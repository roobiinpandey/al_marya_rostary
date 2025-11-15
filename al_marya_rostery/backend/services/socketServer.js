/**
 * Socket.IO Server Configuration
 * Handles real-time delivery tracking, payment updates, and order status
 */

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');

class SocketServer {
  constructor(httpServer) {
    this.io = new Server(httpServer, {
      cors: {
        origin: [
          'http://localhost:3000',
          'http://localhost:5173',
          'https://al-marya-rostery.onrender.com',
          process.env.FRONTEND_URL,
          process.env.ADMIN_URL,
        ].filter(Boolean),
        methods: ['GET', 'POST'],
        credentials: true,
      },
      pingTimeout: 60000,
      pingInterval: 25000,
    });

    this.setupMiddleware();
    this.setupNamespaces();
    this.connectedClients = new Map(); // Track active connections
  }

  /**
   * JWT Authentication Middleware
   */
  setupMiddleware() {
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];

        if (!token) {
          return next(new Error('Authentication token required'));
        }

        // Try Firebase token first
        try {
          const decodedToken = await admin.auth().verifyIdToken(token);
          socket.userId = decodedToken.uid;
          socket.userEmail = decodedToken.email;
          socket.authType = 'firebase';
          return next();
        } catch (firebaseError) {
          // Try JWT token
          const decoded = jwt.verify(token, process.env.JWT_SECRET);
          socket.userId = decoded.id || decoded.userId;
          socket.userEmail = decoded.email;
          socket.authType = 'jwt';
          return next();
        }
      } catch (error) {
        console.error('Socket authentication failed:', error.message);
        return next(new Error('Invalid authentication token'));
      }
    });
  }

  /**
   * Setup Event Namespaces
   */
  setupNamespaces() {
    // Main namespace (default)
    this.setupDefaultNamespace();

    // User namespace
    this.userNamespace = this.io.of('/user');
    this.setupUserNamespace();

    // Driver namespace
    this.driverNamespace = this.io.of('/driver');
    this.setupDriverNamespace();

    // Admin namespace
    this.adminNamespace = this.io.of('/admin');
    this.setupAdminNamespace();
  }

  /**
   * Default Namespace - General Events
   */
  setupDefaultNamespace() {
    this.io.on('connection', (socket) => {
      console.log(`✅ Socket connected: ${socket.id} (User: ${socket.userId})`);

      // Track connection
      this.connectedClients.set(socket.id, {
        userId: socket.userId,
        email: socket.userEmail,
        connectedAt: new Date(),
      });

      // Heartbeat
      socket.on('ping', () => {
        socket.emit('pong', { timestamp: Date.now() });
      });

      // Join order room
      socket.on('join_order_room', ({ orderId }) => {
        socket.join(`order_${orderId}`);
        console.log(`📦 User ${socket.userId} joined order room: ${orderId}`);
        socket.emit('joined_room', { orderId, room: `order_${orderId}` });
      });

      // Leave order room
      socket.on('leave_order_room', ({ orderId }) => {
        socket.leave(`order_${orderId}`);
        console.log(`📦 User ${socket.userId} left order room: ${orderId}`);
      });

      // Disconnect
      socket.on('disconnect', (reason) => {
        console.log(`❌ Socket disconnected: ${socket.id} - Reason: ${reason}`);
        this.connectedClients.delete(socket.id);
      });
    });
  }

  /**
   * User Namespace - Customer app events
   */
  setupUserNamespace() {
    this.userNamespace.use(this.io._nsps.get('/').middlewares);

    this.userNamespace.on('connection', (socket) => {
      console.log(`👤 User connected: ${socket.id}`);

      // User joins their orders
      socket.on('subscribe_to_orders', ({ userId }) => {
        socket.join(`user_orders_${userId}`);
        console.log(`👤 User ${userId} subscribed to their orders`);
      });

      socket.on('disconnect', () => {
        console.log(`👤 User disconnected: ${socket.id}`);
      });
    });
  }

  /**
   * Driver Namespace - Driver app events
   */
  setupDriverNamespace() {
    this.driverNamespace.use(this.io._nsps.get('/').middlewares);

    this.driverNamespace.on('connection', (socket) => {
      console.log(`🚗 Driver connected: ${socket.id}`);

      // Driver location update
      socket.on('driver_location_update', async (data) => {
        const { orderId, driverId, lat, lng, speed, heading, accuracy } = data;

        // Validate
        if (!orderId || !lat || !lng) {
          return socket.emit('error', { message: 'Invalid location data' });
        }

        // Save to database (handled in separate service)
        const locationUpdate = {
          orderId,
          driverId: driverId || socket.userId,
          currentLocation: {
            latitude: lat,
            longitude: lng,
            accuracy: accuracy || null,
            heading: heading || null,
            speed: speed || null,
            updatedAt: new Date(),
          },
        };

        // Emit to handler
        this.io.emit('internal_driver_location_update', locationUpdate);

        // Broadcast to all clients in order room
        this.io.to(`order_${orderId}`).emit('driver_location_update', {
          orderId,
          location: {
            lat,
            lng,
            speed,
            heading,
            timestamp: Date.now(),
          },
        });
      });

      // Payment confirmation (COD)
      socket.on('payment_confirm', async (data) => {
        const { orderId, driverId, method, confirmed, amount } = data;

        if (!orderId || !confirmed) {
          return socket.emit('error', { message: 'Invalid payment confirmation' });
        }

        // Emit for backend processing
        this.io.emit('internal_payment_confirm', {
          orderId,
          driverId: driverId || socket.userId,
          method,
          confirmed,
          amount,
          confirmedAt: new Date(),
        });

        socket.emit('payment_confirm_ack', { orderId, success: true });
      });

      socket.on('disconnect', () => {
        console.log(`🚗 Driver disconnected: ${socket.id}`);
      });
    });
  }

  /**
   * Admin Namespace - Admin panel events
   */
  setupAdminNamespace() {
    this.adminNamespace.use(this.io._nsps.get('/').middlewares);

    this.adminNamespace.on('connection', (socket) => {
      console.log(`👨‍💼 Admin connected: ${socket.id}`);

      // Subscribe to all active deliveries
      socket.on('subscribe_to_deliveries', () => {
        socket.join('all_deliveries');
        console.log(`👨‍💼 Admin subscribed to all deliveries`);
      });

      socket.on('disconnect', () => {
        console.log(`👨‍💼 Admin disconnected: ${socket.id}`);
      });
    });
  }

  /**
   * Broadcast order status update
   */
  emitOrderStatusUpdate(orderId, status, data = {}) {
    this.io.to(`order_${orderId}`).emit('order_status_update', {
      orderId,
      status,
      ...data,
      timestamp: Date.now(),
    });

    // Also broadcast to admin
    this.adminNamespace.to('all_deliveries').emit('order_status_update', {
      orderId,
      status,
      ...data,
      timestamp: Date.now(),
    });

    console.log(`📢 Order status update: ${orderId} → ${status}`);
  }

  /**
   * Broadcast payment update
   */
  emitPaymentUpdate(orderId, paymentData) {
    this.io.to(`order_${orderId}`).emit('payment_update', {
      orderId,
      ...paymentData,
      timestamp: Date.now(),
    });

    console.log(`💳 Payment update: ${orderId} → ${paymentData.paymentStatus}`);
  }

  /**
   * Broadcast driver assignment
   */
  emitDriverAssigned(orderId, driverData) {
    this.io.to(`order_${orderId}`).emit('driver_assigned', {
      orderId,
      driver: driverData,
      timestamp: Date.now(),
    });

    console.log(`🚗 Driver assigned to order: ${orderId}`);
  }

  /**
   * Get connected clients count
   */
  getStats() {
    return {
      totalConnections: this.connectedClients.size,
      namespaces: {
        default: this.io.sockets.sockets.size,
        user: this.userNamespace.sockets.size,
        driver: this.driverNamespace.sockets.size,
        admin: this.adminNamespace.sockets.size,
      },
    };
  }
}

module.exports = SocketServer;
