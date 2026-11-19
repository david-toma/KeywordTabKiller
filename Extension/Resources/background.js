"use strict";

const api = typeof browser !== "undefined" ? browser : chrome;

// Safari ignores the application id, but the argument is still required.
const NATIVE_APP_ID = "com.keywordblocker.app";
const CACHE_KEY = "blockedKeywords";
const SYNC_INTERVAL_MS = 2000;

let keywords = [];          // normalized
let cacheLoaded = null;     // Promise
let firstSync = null;       // Promise
let syncing = null;         // Promise
let lastSync = 0;
const closing = new Set();  // tab ids currently being closed

// ---------- text helpers ----------

// Decode %XX and '+' (as space). Handles double-encoding and malformed sequences.
function safeDecode(input) {
  let s = String(input).replace(/\+/g, " ");
  for (let i = 0; i < 3; i++) {
    let next;
    try {
      next = decodeURIComponent(s);
    } catch (_) {
      // Malformed sequence somewhere: decode valid runs only.
      next = s.replace(/(?:%[0-9a-fA-F]{2})+/g, (run) => {
        try { return decodeURIComponent(run); } catch (_) { return run; }
      });
    }
    if (next === s) break;
    s = next;
  }
  return s;
}

// Lowercase, strip accents, collapse whitespace.
function normalize(s) {
  return String(s)
    .normalize("NFKC")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function findBlockedWord(url) {
  if (!/^https?:/i.test(url) || keywords.length === 0) return null;
  const decoded = normalize(safeDecode(url));
  const spaced = decoded.replace(/[-_]+/g, " ");
  for (const kw of keywords) {
    if (decoded.includes(kw) || spaced.includes(kw)) return kw;
  }
  return null;
}

// ---------- keyword list (native + cache) ----------

function setKeywords(list) {
  keywords = (Array.isArray(list) ? list : []).map(normalize).filter(Boolean);
}

function loadCache() {
  return api.storage.local
    .get(CACHE_KEY)
    .then((res) => setKeywords(res && res[CACHE_KEY]))
    .catch((e) => console.warn("cache load failed", e));
}

function syncFromNative(force = false) {
  if (syncing) return syncing;
  const now = Date.now();
  if (!force && now - lastSync < SYNC_INTERVAL_MS) return Promise.resolve();
  lastSync = now;
  syncing = api.runtime
    .sendNativeMessage(NATIVE_APP_ID, { type: "getKeywords" })
    .then((resp) => {
      if (resp && Array.isArray(resp.keywords)) {
        setKeywords(resp.keywords);
        return api.storage.local.set({ [CACHE_KEY]: resp.keywords });
      }
    })
    .catch((e) => console.warn("native sync failed", e))
    .finally(() => { syncing = null; });
  return syncing;
}

async function ensureReady() {
  if (!cacheLoaded) cacheLoaded = loadCache();
  await cacheLoaded;
  if (!firstSync) firstSync = syncFromNative(true);
  await firstSync;
}

// ---------- blocking ----------

async function check(tabId, url) {
  if (typeof tabId !== "number" || tabId < 0 || !url) return;
  await ensureReady();
  syncFromNative(); // throttled background refresh, not awaited

  const hit = findBlockedWord(url);
  if (!hit || closing.has(tabId)) return;

  closing.add(tabId);
  try {
    await api.tabs.remove(tabId);
  } catch (e) {
    console.warn("tabs.remove failed", e);
  } finally {
    setTimeout(() => closing.delete(tabId), 1000);
  }
}

// Listeners must be registered synchronously at top level (non-persistent background).
api.webNavigation.onBeforeNavigate.addListener((details) => {
  if (details.frameId === 0) check(details.tabId, details.url);
});

api.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  const url = changeInfo.url || (changeInfo.status === "loading" ? tab && tab.url : null);
  if (url) check(tabId, url);
});

api.runtime.onInstalled.addListener(() => syncFromNative(true));
api.runtime.onStartup.addListener(() => syncFromNative(true));
