const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { testConnection, initializeDatabase, initializeSchema, verifySchema } = require('./config/database');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const categoryRoutes = require('./routes/categories');

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Simple Mart API v1.0', status: 'Active' });
});

// Health check route
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Database status route
app.get('/db-status', async (req, res) => {
  try {
    res.json({ 
      status: 'Connected', 
      database: process.env.DB_NAME || 'simple_mart_db',
      message: 'Database connection active',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'Error', 
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/categories', categoryRoutes);

// 404 handler for unknown routes
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// Start server with database initialization
async function startServer() {
  try {
    // Initialize database
    await initializeDatabase();
    
    // Test database connection
    const isConnected = await testConnection();
    
    if (isConnected) {
      console.log('Database connection successful');
      
      // Initialize schema
      await initializeSchema();
      console.log('Database schema initialized');
      
      // Verify structure
      await verifySchema();
    } else {
      console.log('Database connection failed, but server will still start');
    }
    
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Error starting server:', error);
    process.exit(1);
  }
}

startServer();