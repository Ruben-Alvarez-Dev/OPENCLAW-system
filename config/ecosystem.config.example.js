/**
 * PM2 Ecosystem Configuration for OPENCLAW
 *
 * Copy to: ~/projects/openclaw/ecosystem.config.js
 * Usage: pm2 start ecosystem.config.js
 */

module.exports = {
  apps: [
    // Gateway - Message broker
    {
      name: 'openclaw-gateway',
      script: 'dist/cli/openclaw.js',
      args: 'gateway start --port 18789',
      cwd: process.env.HOME + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '500M',

      env: {
        NODE_ENV: 'production',
        LOG_LEVEL: 'info',
        GATEWAY_URL: 'ws://127.0.0.1:18789'
      },

      env_file: process.env.HOME + '/.openclaw/config/.env',

      error_file: process.env.HOME + '/.openclaw/logs/gateway-error.log',
      out_file: process.env.HOME + '/.openclaw/logs/gateway-out.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },

    // Orchestrator Manager
    {
      name: 'openclaw-manager',
      script: 'dist/cli/openclaw.js',
      args: 'gear start manager --gateway ws://127.0.0.1:18789',
      cwd: process.env.HOME + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',

      env: {
        NODE_ENV: 'production'
      },

      env_file: process.env.HOME + '/.openclaw/config/.env',

      error_file: process.env.HOME + '/.openclaw/logs/manager-error.log',
      out_file: process.env.HOME + '/.openclaw/logs/manager-out.log',
      time: true
    },

    // Orchestrator Worker
    {
      name: 'openclaw-worker',
      script: 'dist/cli/openclaw.js',
      args: 'gear start worker --gateway ws://127.0.0.1:18789',
      cwd: process.env.HOME + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '2G',

      env: {
        NODE_ENV: 'production'
      },

      env_file: process.env.HOME + '/.openclaw/config/.env',

      error_file: process.env.HOME + '/.openclaw/logs/worker-error.log',
      out_file: process.env.HOME + '/.openclaw/logs/worker-out.log',
      time: true
    },

    // Orchestrator Archivist
    {
      name: 'openclaw-archivist',
      script: 'dist/cli/openclaw.js',
      args: 'gear start archivist --gateway ws://127.0.0.1:18789',
      cwd: process.env.HOME + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',

      env: {
        NODE_ENV: 'production'
      },

      env_file: process.env.HOME + '/.openclaw/config/.env',

      error_file: process.env.HOME + '/.openclaw/logs/archivist-error.log',
      out_file: process.env.HOME + '/.openclaw/logs/archivist-out.log',
      time: true
    }
  ]
};
