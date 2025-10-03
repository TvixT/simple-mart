const User = require('./models/User');
const Product = require('./models/Product');
const Cart = require('./models/Cart');

// Simple test without complex transactions
async function simpleModelTest() {
  console.log('🧪 Running Simple Model Tests...\n');

  try {
    // Test User Model
    console.log('1️⃣ Testing User Model...');
    
    const userData = {
      name: 'Test User',
      email: `test${Date.now()}@example.com`,
      password: 'password123'
    };
    
    const user = await User.create(userData);
    console.log('✅ User created:', user.name);
    
    // Test Product Model
    console.log('\n2️⃣ Testing Product Model...');
    
    // Add a category first
    const { promisePool } = require('./config/database');
    const [categoryResult] = await promisePool.execute(
      'INSERT INTO categories (name, description) VALUES (?, ?)',
      ['Test Category', 'Test category description']
    );
    
    const productData = {
      name: 'Test Product',
      description: 'A test product',
      price: 99.99,
      stock: 10,
      image_url: 'test.jpg',
      category_id: categoryResult.insertId
    };
    
    const product = await Product.create(productData);
    console.log('✅ Product created:', product.name, `$${product.price}`);
    
    // Test Cart Model
    console.log('\n3️⃣ Testing Cart Model...');
    
    const cartItem = await Cart.addItem(user.id, product.id, 1);
    console.log('✅ Item added to cart:', cartItem.quantity, 'x', cartItem.product.name);
    
    const userCart = await Cart.getUserCart(user.id);
    console.log('✅ User cart:', userCart.summary.total_items, 'items');
    
    // Test update operations
    console.log('\n4️⃣ Testing Update Operations...');
    
    const updatedUser = await User.update(user.id, {
      name: 'Updated User',
      email: user.email
    });
    console.log('✅ User updated:', updatedUser.name);
    
    const updatedProduct = await Product.updateStock(product.id, 15, 'set');
    console.log('✅ Product stock updated:', updatedProduct.stock);
    
    const updatedCartItem = await Cart.updateQuantity(user.id, product.id, 3);
    console.log('✅ Cart quantity updated:', updatedCartItem.quantity);
    
    // Test statistics
    console.log('\n5️⃣ Testing Statistics...');
    
    const productStats = await Product.getStats();
    console.log('✅ Product stats - Total products:', productStats.total_products);
    
    const cartStats = await Cart.getStats();
    console.log('✅ Cart stats - Active carts:', cartStats.active_carts);
    
    console.log('\n✅ All simple tests completed successfully! 🎉');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run tests
simpleModelTest()
  .then(() => {
    console.log('\n🏁 Simple test execution completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Test execution failed:', error);
    process.exit(1);
  });