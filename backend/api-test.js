const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

// Test data
const testUser = {
  username: 'testuser',
  email: 'testuser@example.com',
  password: 'password123',
  full_name: 'Test User'
};

const testProduct = {
  name: 'Test Product',
  description: 'A test product for API testing',
  price: 29.99,
  category_id: 1,
  stock_quantity: 100,
  image_url: 'https://example.com/product.jpg'
};

let authToken = '';
let userId = '';
let productId = '';
let cartId = '';
let orderId = '';

// Helper function to log test results
const logTest = (testName, success, data = null, error = null) => {
  console.log(`\n${success ? '✅' : '❌'} ${testName}`);
  if (data && success) {
    console.log('   Response:', JSON.stringify(data, null, 2));
  }
  if (error) {
    console.log('   Error:', error.message);
    if (error.response && error.response.data) {
      console.log('   Details:', JSON.stringify(error.response.data, null, 2));
    }
  }
};

// Test functions
async function testHealthCheck() {
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    logTest('Health Check', true, response.data);
    return true;
  } catch (error) {
    logTest('Health Check', false, null, error);
    return false;
  }
}

async function testUserRegistration() {
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/register`, testUser);
    userId = response.data.user.id;
    logTest('User Registration', true, response.data);
    return true;
  } catch (error) {
    logTest('User Registration', false, null, error);
    return false;
  }
}

async function testUserLogin() {
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: testUser.email,
      password: testUser.password
    });
    authToken = response.data.token;
    logTest('User Login', true, response.data);
    return true;
  } catch (error) {
    logTest('User Login', false, null, error);
    return false;
  }
}

async function testCreateProduct() {
  try {
    const response = await axios.post(`${BASE_URL}/api/products`, testProduct, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    productId = response.data.product.id;
    logTest('Create Product', true, response.data);
    return true;
  } catch (error) {
    logTest('Create Product', false, null, error);
    return false;
  }
}

async function testGetProducts() {
  try {
    const response = await axios.get(`${BASE_URL}/api/products`);
    logTest('Get Products', true, response.data);
    return true;
  } catch (error) {
    logTest('Get Products', false, null, error);
    return false;
  }
}

async function testAddToCart() {
  try {
    const response = await axios.post(`${BASE_URL}/api/cart`, {
      product_id: productId,
      quantity: 2
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    cartId = response.data.cart.id;
    logTest('Add to Cart', true, response.data);
    return true;
  } catch (error) {
    logTest('Add to Cart', false, null, error);
    return false;
  }
}

async function testGetCart() {
  try {
    const response = await axios.get(`${BASE_URL}/api/cart`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    logTest('Get Cart', true, response.data);
    return true;
  } catch (error) {
    logTest('Get Cart', false, null, error);
    return false;
  }
}

async function testCreateOrder() {
  try {
    const response = await axios.post(`${BASE_URL}/api/orders`, {
      shipping_address: '123 Test Street, Test City, TC 12345'
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    orderId = response.data.order.id;
    logTest('Create Order', true, response.data);
    return true;
  } catch (error) {
    logTest('Create Order', false, null, error);
    return false;
  }
}

async function testGetOrders() {
  try {
    const response = await axios.get(`${BASE_URL}/api/orders/user`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    logTest('Get Orders', true, response.data);
    return true;
  } catch (error) {
    logTest('Get Orders', false, null, error);
    return false;
  }
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting API Tests...');
  
  const tests = [
    { name: 'Health Check', func: testHealthCheck },
    { name: 'User Registration', func: testUserRegistration },
    { name: 'User Login', func: testUserLogin },
    { name: 'Create Product', func: testCreateProduct },
    { name: 'Get Products', func: testGetProducts },
    { name: 'Add to Cart', func: testAddToCart },
    { name: 'Get Cart', func: testGetCart },
    { name: 'Create Order', func: testCreateOrder },
    { name: 'Get Orders', func: testGetOrders }
  ];
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    const result = await test.func();
    if (result) {
      passed++;
    } else {
      failed++;
    }
    
    // Add delay between tests
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  console.log(`\n📊 Test Results:`);
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${((passed / (passed + failed)) * 100).toFixed(1)}%`);
  
  if (failed === 0) {
    console.log('\n🎉 All tests passed! API is working correctly.');
  } else {
    console.log('\n⚠️  Some tests failed. Check the errors above.');
  }
}

// Run the tests
runAllTests().catch(console.error);