// Test admin authentication and CRUD operations
const API_BASE = 'http://localhost:5000/api';

async function testAdminAuth() {
  try {
    console.log('🔐 Testing admin authentication...');
    
    // Test admin login
    const loginResponse = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'admin@example.com',
        password: 'admin123'
      })
    });

    const loginData = await loginResponse.json();
    
    if (!loginResponse.ok) {
      console.error('❌ Admin login failed:', loginData);
      return;
    }

    console.log('✅ Admin login successful!');
    console.log('Token received:', loginData.data?.tokens?.accessToken ? 'Yes' : 'No');
    console.log('User role:', loginData.data?.user?.role);

    const token = loginData.data.tokens.accessToken;

    // Test getting products (public route)
    console.log('\n📦 Testing public product listing...');
    const productsResponse = await fetch(`${API_BASE}/products`);
    const productsData = await productsResponse.json();
    console.log('Public products:', productsData.success ? `${productsData.data.products.length} products found` : 'Failed');

    // Test admin-only product creation
    console.log('\n🔧 Testing admin product creation...');
    const createResponse = await fetch(`${API_BASE}/products`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        name: 'Test Admin Product',
        description: 'Product created by admin',
        price: 99.99,
        stock: 50,
        image_url: 'https://example.com/image.jpg',
        category_id: 1
      })
    });

    const createData = await createResponse.json();
    console.log('Product creation:', createResponse.ok ? '✅ Success' : '❌ Failed');
    console.log('Response:', createData);

    if (createResponse.ok && createData.data?.product?.id) {
      const productId = createData.data.product.id;
      
      // Test admin-only product update
      console.log('\n✏️ Testing admin product update...');
      const updateResponse = await fetch(`${API_BASE}/products/${productId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          name: 'Updated Admin Product',
          price: 129.99
        })
      });

      const updateData = await updateResponse.json();
      console.log('Product update:', updateResponse.ok ? '✅ Success' : '❌ Failed');
      console.log('Response:', updateData);

      // Test admin-only product deletion
      console.log('\n🗑️ Testing admin product deletion...');
      const deleteResponse = await fetch(`${API_BASE}/products/${productId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const deleteData = await deleteResponse.json();
      console.log('Product deletion:', deleteResponse.ok ? '✅ Success' : '❌ Failed');
      console.log('Response:', deleteData);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Test non-admin access
async function testCustomerAuth() {
  try {
    console.log('\n👤 Testing customer access to admin routes...');
    
    // First register a customer
    const registerResponse = await fetch(`${API_BASE}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: 'Test Customer',
        email: 'customer@example.com',
        password: 'customer123'
      })
    });

    const registerData = await registerResponse.json();
    
    if (registerResponse.ok) {
      const token = registerData.data.tokens.accessToken;
      
      // Try to create a product as customer (should fail)
      const createResponse = await fetch(`${API_BASE}/products`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          name: 'Customer Product',
          price: 50.00
        })
      });

      const createData = await createResponse.json();
      console.log('Customer product creation:', createResponse.ok ? '❌ Should have failed' : '✅ Correctly blocked');
      console.log('Response:', createData);
    }

  } catch (error) {
    console.error('❌ Customer test failed:', error.message);
  }
}

// Run tests
console.log('🚀 Starting admin CRUD tests...\n');
testAdminAuth().then(() => {
  return testCustomerAuth();
}).then(() => {
  console.log('\n✅ All tests completed!');
}).catch(error => {
  console.error('❌ Test suite failed:', error);
});