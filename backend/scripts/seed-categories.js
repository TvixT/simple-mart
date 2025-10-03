require('dotenv').config();
const Category = require('../models/Category');

async function seedCategories() {
  try {
    console.log('🌱 Seeding categories...');

    // Check if we have fewer than 5 categories (force seed more)
    const existingCategories = await Category.getAll({ limit: 10 });
    if (existingCategories.categories.length >= 5) {
      console.log('Sufficient categories already exist, skipping seed...');
      console.log('Existing categories:');
      existingCategories.categories.forEach(cat => {
        console.log(`- ${cat.name}: ${cat.description}`);
      });
      return;
    }

    const categories = [
      {
        name: 'Electronics',
        description: 'Electronic devices, gadgets, and accessories including phones, laptops, headphones, and smart devices.'
      },
      {
        name: 'Clothing & Fashion',
        description: 'Apparel, shoes, accessories, and fashion items for men, women, and children.'
      },
      {
        name: 'Home & Garden',
        description: 'Home decor, furniture, gardening supplies, and household essentials.'
      },
      {
        name: 'Books & Media',
        description: 'Books, magazines, movies, music, and educational materials.'
      },
      {
        name: 'Sports & Outdoors',
        description: 'Sports equipment, outdoor gear, fitness accessories, and recreational items.'
      },
      {
        name: 'Health & Beauty',
        description: 'Personal care products, cosmetics, skincare, and health supplements.'
      },
      {
        name: 'Toys & Games',
        description: 'Toys, board games, video games, and entertainment for all ages.'
      },
      {
        name: 'Food & Beverages',
        description: 'Groceries, snacks, beverages, and specialty food items.'
      },
      {
        name: 'Automotive',
        description: 'Car parts, accessories, tools, and automotive maintenance products.'
      },
      {
        name: 'Office & School',
        description: 'Office supplies, stationery, school materials, and business equipment.'
      }
    ];

    console.log(`Creating ${categories.length} categories...`);

    for (const categoryData of categories) {
      try {
        const category = await Category.create(categoryData);
        console.log(`✅ Created: ${category.name}`);
      } catch (error) {
        console.error(`❌ Failed to create ${categoryData.name}:`, error.message);
      }
    }

    // Display final count
    const finalCategories = await Category.getAllWithProductCounts();
    console.log(`\n🎉 Seeding completed! Total categories: ${finalCategories.length}`);
    
    // Show created categories
    console.log('\nCreated categories:');
    finalCategories.forEach(cat => {
      console.log(`- ${cat.name}: ${cat.description}`);
    });

  } catch (error) {
    console.error('❌ Error seeding categories:', error.message);
  } finally {
    process.exit(0);
  }
}

seedCategories();