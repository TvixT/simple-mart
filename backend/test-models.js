const User = require('./models/User');
const Product = require('./models/Product');
const Cart = require('./models/Cart');
const Order = require('./models/Order');

// Test script to verify all models work correctly
async function testModels() {
  console.log('🧪 Starting database model tests...\n');

  try {
    // Test 1: User Model
    console.log('1️⃣ Testing User Model...');
    
    // Create a test user
    const userData = {
      name: 'John Doe',
      email: 'john.doe@example.com',
      password: 'password123'
    };
    
    const user = await User.create(userData);
    console.log('✅ User created:', user.name, user.email);
    
    // Find user by email
    const foundUser = await User.findByEmail(userData.email);
    console.log('✅ User found by email:', foundUser.name);
    
    // Test 2: Product Model
    console.log('\n2️⃣ Testing Product Model...');
    
    // Create test categories first
    const { promisePool } = require('./config/database');
    const [categoryResult] = await promisePool.execute(
      'INSERT INTO categories (name, description) VALUES (?, ?)',
      ['Electronics', 'Electronic devices and gadgets']
    );
    
    // Create test products
    const productData = {
      name: 'Smartphone',
      description: 'Latest smartphone with advanced features',
      price: 699.99,
      stock: 50,
      image_url: 'https://example.com/smartphone.jpg',
      category_id: categoryResult.insertId
    };
    
    const product = await Product.create(productData);
    console.log('✅ Product created:', product.name, `$${product.price}`);
    
    // Test product search
    const searchResults = await Product.search('smartphone');
    console.log('✅ Product search results:', searchResults.products.length, 'products found');
    
    // Test 3: Cart Model
    console.log('\n3️⃣ Testing Cart Model...');
    
    // Add item to cart
    const cartItem = await Cart.addItem(user.id, product.id, 2);
    console.log('✅ Item added to cart:', cartItem.quantity, 'x', cartItem.product.name);
    
    // Get user's cart
    const userCart = await Cart.getUserCart(user.id);
    console.log('✅ User cart retrieved:', userCart.summary.total_items, 'items, $' + userCart.summary.subtotal);
    
    // Test 4: Order Model
    console.log('\n4️⃣ Testing Order Model...');
    
    // Create order from cart
    const shippingAddress = '123 Main St, City, State 12345';
    const order = await Order.createFromCart(user.id, shippingAddress);
    console.log('✅ Order created from cart:', order.id, 'total: $' + order.total_price);
    
    // Get order with items
    const orderWithItems = await Order.getOrderWithItems(order.id);
    console.log('✅ Order with items retrieved:', orderWithItems.items.length, 'items');
    
    // Test 5: Additional Operations
    console.log('\n5️⃣ Testing Additional Operations...');
    
    // Update order status
    const updatedOrder = await Order.updateStatus(order.id, 'processing');
    console.log('✅ Order status updated to:', updatedOrder.status);
    
    // Check product stock after order
    const updatedProduct = await Product.findById(product.id);
    console.log('✅ Product stock after order:', updatedProduct.stock);
    
    // Get statistics
    const userStats = await User.getStats();
    const productStats = await Product.getStats();
    const orderStats = await Order.getStats();
    
    console.log('\n📊 Statistics:');
    console.log('- Users created today:', userStats.length);
    console.log('- Total products:', productStats.total_products);
    console.log('- In stock products:', productStats.in_stock_products);
    console.log('- Total orders:', orderStats.total_orders);
    console.log('- Total revenue: $' + parseFloat(orderStats.total_revenue || 0).toFixed(2));
    
    console.log('\n✅ All model tests completed successfully! 🎉');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  testModels()
    .then(() => {
      console.log('\n🏁 Test execution completed.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Test execution failed:', error);
      process.exit(1);
    });
}

module.exports = { testModels };