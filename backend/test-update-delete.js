// Quick test of update and delete with existing product
const API_BASE = 'http://localhost:5000/api';

async function testUpdateDelete() {
  try {
    console.log('🔐 Testing admin authentication...');
    
    // Login as admin
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

    const token = loginData.data.tokens.accessToken;
    const productId = 2; // Use the existing product

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

    // Test customer trying to access admin route
    console.log('\n👤 Testing customer access restriction...');
    
    // Register customer
    const registerResponse = await fetch(`${API_BASE}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: 'Test Customer 2',
        email: 'customer2@example.com',
        password: 'customer123'
      })
    });

    if (registerResponse.ok) {
      const customerData = await registerResponse.json();
      const customerToken = customerData.data.tokens.accessToken;
      
      // Try to update product as customer (should fail)
      const customerUpdateResponse = await fetch(`${API_BASE}/products/${productId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${customerToken}`
        },
        body: JSON.stringify({
          name: 'Customer Product',
          price: 50.00
        })
      });

      const customerUpdateData = await customerUpdateResponse.json();
      console.log('Customer product update:', customerUpdateResponse.ok ? '❌ Should have failed' : '✅ Correctly blocked');
      console.log('Response:', customerUpdateData);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testUpdateDelete();