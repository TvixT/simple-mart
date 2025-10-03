const axios = require('axios');

async function testProductUpdate() {
  try {
    // First, get a list of products
    console.log('🔍 Getting products...');
    const getResponse = await axios.get('http://localhost:5000/api/products');
    
    if (getResponse.data.data.products.length === 0) {
      console.log('❌ No products found. Create a product first.');
      return;
    }
    
    const product = getResponse.data.data.products[0];
    console.log('📦 Testing with product:', product.name);
    console.log('📊 Current stock:', product.stock);
    
    // Test updating the stock
    const newStock = product.stock + 10;
    console.log(`🔄 Updating stock from ${product.stock} to ${newStock}...`);
    
    const updateResponse = await axios.put(`http://localhost:5000/api/products/${product.id}`, {
      stock: newStock
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Update response:', updateResponse.data);
    
    // Verify the update
    const verifyResponse = await axios.get(`http://localhost:5000/api/products/${product.id}`);
    console.log('🔍 Verified stock:', verifyResponse.data.data.product.stock);
    
    if (verifyResponse.data.data.product.stock === newStock) {
      console.log('✅ Stock update successful!');
    } else {
      console.log('❌ Stock update failed!');
    }
    
  } catch (error) {
    console.error('❌ Error testing product update:', error.response?.data || error.message);
  }
}

testProductUpdate();