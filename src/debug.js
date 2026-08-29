'use strict';

/**
 * Lightweight, switchable logger with lazy evaluation and log levels.
 * 
 * @module debug
 */

const LEVELS = ['debug', 'info', 'warn', 'error'];
const LEVEL_METHODS = {
  debug: 'debug',
  info: 'info',
  warn: 'warn',
  error: 'error'
};

// Internal state for enabled levels
let enabledLevels = new Set();

/**
 * Parse the DEBUG environment variable to determine enabled levels.
 * @returns {Set<string>} Set of enabled level names
 */
function parseEnvLevels() {
  const debug = process.env.DEBUG;
  const nodeEnv = process.env.NODE_ENV;
  
  // If DEBUG is not set, check NODE_ENV for development mode
  if (!debug) {
    if (nodeEnv === 'development') {
      return new Set(LEVELS);
    }
    return new Set();
  }
  
  // Parse comma-separated list of levels
  const parts = debug.split(',').map(s => s.trim().toLowerCase());
  
  // If DEBUG is 'true' or includes 'debug' as a token, enable all levels
  if (debug === 'true' || parts.includes('debug')) {
    return new Set(LEVELS);
  }
  const levels = new Set();
  for (const part of parts) {
    if (LEVELS.includes(part)) {
      levels.add(part);
    }
  }
  return levels;
}

// Initialize from environment
enabledLevels = parseEnvLevels();

/**
 * Check if a specific level is enabled.
 * @param {string} level - The log level to check
 * @returns {boolean} True if the level is enabled
 */
function isEnabled(level) {
  return enabledLevels.has(level);
}

/**
 * Format a message with timestamp and level prefix.
 * @param {string} level - The log level
 * @param {*} message - The message to format
 * @returns {string} Formatted message
 */
function formatMessage(level, message) {
  const timestamp = new Date().toISOString();
  const msgStr = typeof message === 'object' ? JSON.stringify(message) : String(message);
  return `${timestamp} [${level}] ${msgStr}`;
}

/**
 * Log a message at the specified level.
 * Supports lazy evaluation - if msgOrFn is a function, it will only be called
 * when the message will actually be logged.
 * 
 * @param {string|object|function} msgOrFn - Message string, object, or zero-arg function returning message
 * @param {string} [level='debug'] - Log level: 'debug', 'info', 'warn', 'error'
 */
function debug(msgOrFn, level = 'debug') {
  // Fast path: if level not enabled, do nothing (minimal overhead)
  if (!enabledLevels.has(level)) {
    return;
  }
  
  // Lazy evaluation: only call function if we're actually logging
  const message = typeof msgOrFn === 'function' ? msgOrFn() : msgOrFn;
  
  const formatted = formatMessage(level, message);
  const consoleMethod = LEVEL_METHODS[level] || 'log';
  console[consoleMethod](formatted);
}

/**
 * Enable logging for specific levels.
 * @param {string|string[]} levels - Level name(s) to enable (comma-separated string or array)
 */
debug.enable = function(levels) {
  if (typeof levels === 'string') {
    levels = levels.split(',').map(s => s.trim().toLowerCase());
  }
  enabledLevels = new Set();
  for (const level of levels) {
    if (LEVELS.includes(level)) {
      enabledLevels.add(level);
    }
  }
};

/**
 * Disable all logging.
 */
debug.disable = function() {
  enabledLevels = new Set();
};

/**
 * Check if a specific level is enabled.
 * @param {string} level - The log level to check
 * @returns {boolean} True if the level is enabled
 */
debug.isEnabled = isEnabled;

/**
 * Get list of all available levels.
 * @returns {string[]} Array of level names
 */
debug.levels = LEVELS.slice();

module.exports = debug;
