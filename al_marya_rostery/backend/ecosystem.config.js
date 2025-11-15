module.exports = {
  apps: [{
    name: 'al-marya-backend',
    script: './server.js',
    instances: 1,
    exec_mode: 'fork',
    
    // Auto restart if memory exceeds 80MB (prevents crashes)
    max_memory_restart: '80M',
    
    // Environment variables
    env: {
      NODE_ENV: 'development',
      PORT: 5001
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5001
    },
    
    // Logging
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Auto restart on file changes (development only)
    watch: false,
    ignore_watch: ['node_modules', 'logs', 'uploads', '.git'],
    
    // Restart delay
    restart_delay: 4000,
    
    // Auto restart on crash
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    
    // Graceful shutdown
    kill_timeout: 5000,
    listen_timeout: 3000,
    
    // Monitoring
    monitoring: true
  }]
};
