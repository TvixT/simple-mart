require('dotenv').config();
const { promisePool } = require('../config/database');

async function checkProducts() {
  try {
    console.log('🔍 Checking products in database...');
    
    const [products] = await promisePool.execute('SELECT id, name, stock, price FROM products');
    
    if (products.length === 0) {
      console.log('❌ No products found in database');
    } else {
      console.log(`✅ Found ${products.length} products:`);
      products.forEach(p => {
        console.log(`  - ID: ${p.id}, Name: "${p.name}", Stock: ${p.stock}, Price: $${p.price}`);
      });
    }
    
    await promisePool.end();
  } catch (error) {
    console.error('❌ Error checking products:', error.message);
  } finally {
    process.exit(0);
  }
}

checkProducts();