'use strict';

const assert = require('assert');

// Store original console methods for restoration
const originalConsole = {
  debug: console.debug,
  info: console.info,
  warn: console.warn,
  error: console.error
};

// Test state
let testsPassed = 0;
let testsFailed = 0;
const capturedOutput = [];

/**
 * Stub console methods to capture output
 */
function stubConsole() {
  capturedOutput.length = 0;
  for (const method of ['debug', 'info', 'warn', 'error']) {
    console[method] = (...args) => {
      capturedOutput.push({ method, args });
    };
  }
}

/**
 * Restore original console methods
 */
function restoreConsole() {
  for (const method of ['debug', 'info', 'warn', 'error']) {
    console[method] = originalConsole[method];
  }
}

/**
 * Simple test runner
 */
function test(name, fn) {
  try {
    fn();
    testsPassed++;
    console.log(`✓ ${name}`);
  } catch (err) {
    testsFailed++;
    console.log(`✗ ${name}`);
    console.log(`  Error: ${err.message}`);
  }
}

// Clear require cache to get fresh module with clean state
function freshDebug() {
  delete require.cache[require.resolve('../src/debug.js')];
  return require('../src/debug.js');
}

console.log('Running debug.js tests...\n');

// Test 1: When disabled, debug() does not call the message function
test('When disabled, debug() does not call the message function', () => {
  const debug = freshDebug();
  debug.disable();
  
  let functionCalled = false;
  const msgFn = () => {
    functionCalled = true;
    return 'test message';
  };
  
  debug(msgFn, 'debug');
  
  assert.strictEqual(functionCalled, false, 'Message function should not be called when disabled');
});

// Test 2: When enabled for 'debug', debug() logs using console.debug
test('When enabled for debug level, debug() logs using console.debug', () => {
  const debug = freshDebug();
  debug.enable('debug');
  
  stubConsole();
  try {
    debug('test message', 'debug');
    
    assert.strictEqual(capturedOutput.length, 1, 'Should have captured one log entry');
    assert.strictEqual(capturedOutput[0].method, 'debug', 'Should use console.debug');
    assert.ok(capturedOutput[0].args[0].includes('[debug]'), 'Output should contain level');
    assert.ok(capturedOutput[0].args[0].includes('test message'), 'Output should contain message');
  } finally {
    restoreConsole();
  }
});

// Test 3: Output contains timestamp in ISO format
test('Output contains timestamp in ISO format', () => {
  const debug = freshDebug();
  debug.enable('info');
  
  stubConsole();
  try {
    debug('timestamp test', 'info');
    
    const output = capturedOutput[0].args[0];
    // ISO timestamp pattern: YYYY-MM-DDTHH:MM:SS.sssZ
    const isoPattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/;
    assert.ok(isoPattern.test(output), 'Output should start with ISO timestamp');
  } finally {
    restoreConsole();
  }
});

// Test 4: debug.disable() stops all logging
test('debug.disable() stops all logging', () => {
  const debug = freshDebug();
  debug.enable('debug,info,warn,error');
  
  stubConsole();
  try {
    debug('before disable', 'debug');
    assert.strictEqual(capturedOutput.length, 1, 'Should log when enabled');
    
    debug.disable();
    debug('after disable', 'debug');
    assert.strictEqual(capturedOutput.length, 1, 'Should not log after disable');
  } finally {
    restoreConsole();
  }
});

// Test 5: debug.enable() enables specified levels
test('debug.enable() enables specified levels', () => {
  const debug = freshDebug();
  debug.disable();
  
  debug.enable('info,error');
  
  stubConsole();
  try {
    debug('debug message', 'debug');
    debug('info message', 'info');
    debug('warn message', 'warn');
    debug('error message', 'error');
    
    assert.strictEqual(capturedOutput.length, 2, 'Should only log enabled levels');
    assert.strictEqual(capturedOutput[0].method, 'info', 'First log should be info');
    assert.strictEqual(capturedOutput[1].method, 'error', 'Second log should be error');
  } finally {
    restoreConsole();
  }
});

// Test 6: Lazy evaluation - function is called when logging is enabled
test('Lazy evaluation - function is called when logging is enabled', () => {
  const debug = freshDebug();
  debug.enable('debug');
  
  let functionCalled = false;
  const msgFn = () => {
    functionCalled = true;
    return 'lazy message';
  };
  
  stubConsole();
  try {
    debug(msgFn, 'debug');
    
    assert.strictEqual(functionCalled, true, 'Message function should be called when enabled');
    assert.ok(capturedOutput[0].args[0].includes('lazy message'), 'Output should contain function result');
  } finally {
    restoreConsole();
  }
});

// Test 7: Object messages are JSON stringified
test('Object messages are JSON stringified', () => {
  const debug = freshDebug();
  debug.enable('debug');
  
  stubConsole();
  try {
    debug({ key: 'value', num: 42 }, 'debug');
    
    const output = capturedOutput[0].args[0];
    assert.ok(output.includes('"key":"value"'), 'Output should contain JSON stringified object');
  } finally {
    restoreConsole();
  }
});

// Test 8: Different log levels use appropriate console methods
test('Different log levels use appropriate console methods', () => {
  const debug = freshDebug();
  debug.enable('debug,info,warn,error');
  
  stubConsole();
  try {
    debug('debug msg', 'debug');
    debug('info msg', 'info');
    debug('warn msg', 'warn');
    debug('error msg', 'error');
    
    assert.strictEqual(capturedOutput[0].method, 'debug');
    assert.strictEqual(capturedOutput[1].method, 'info');
    assert.strictEqual(capturedOutput[2].method, 'warn');
    assert.strictEqual(capturedOutput[3].method, 'error');
  } finally {
    restoreConsole();
  }
});

// Test 9: Default level is 'debug'
test('Default level is debug when not specified', () => {
  const debug = freshDebug();
  debug.enable('debug');
  
  stubConsole();
  try {
    debug('default level message');
    
    assert.strictEqual(capturedOutput.length, 1);
    assert.strictEqual(capturedOutput[0].method, 'debug');
    assert.ok(capturedOutput[0].args[0].includes('[debug]'));
  } finally {
    restoreConsole();
  }
});

// Test 10: debug.isEnabled() returns correct state
test('debug.isEnabled() returns correct state', () => {
  const debug = freshDebug();
  debug.disable();
  
  assert.strictEqual(debug.isEnabled('debug'), false);
  assert.strictEqual(debug.isEnabled('info'), false);
  
  debug.enable('info,error');
  
  assert.strictEqual(debug.isEnabled('debug'), false);
  assert.strictEqual(debug.isEnabled('info'), true);
  assert.strictEqual(debug.isEnabled('warn'), false);
  assert.strictEqual(debug.isEnabled('error'), true);
});

// Print results
console.log(`\n${testsPassed} passing, ${testsFailed} failing`);

if (testsFailed > 0) {
  process.exit(1);
}
