<template>
  <div class="input-group mb-3">
    <input v-model.trim="searchQuery" class="form-control form-control-lg"
           type="text" maxlength="100" placeholder="Search" aria-label="Search query">
    <button @click="clear()" :disabled="!searchQuery" class="btn btn-secondary" type="button">
      Clear
    </button>
  </div>

  <ul class="list-group">
    <li v-for="product in filteredProductList" :key="product.id"
        class="list-group-item d-flex justify-content-between align-items-center">
      <ProductItem :product="product" :highlight="searchQuery.toLowerCase()"></ProductItem>
    </li>
  </ul>
</template>

<script lang="ts">
import {defineComponent} from 'vue';
import {Product} from '@/types/product';
import ProductItem from '@/components/ProductItem.vue';
import {ProductDTO} from '@/types/productDTO';
import {Variant} from '@/types/variant';

export default defineComponent({
  name: 'ProductList',
  components: {ProductItem},
  data() {
    return {
      productList: [] as Product[],
      searchQuery: '' as string
    }
  },
  computed: {
    filteredProductList() {
      return this.productList.filter(product => {
        const query = this.searchQuery.toLowerCase();

        return product.title.toLowerCase().includes(query) || product.variants.map(variant => variant.sku.toLowerCase()).filter(sku => sku.includes(query)).length > 0;
      })
    }
  },
  mounted() {
    this.getAll();
  },
  methods: {
    clear(): void {
      this.searchQuery = '';
    },
    async getAll(): Promise<void> {
      const maxCacheAge = 5 * 60 * 1000;
      const data = this.loadFromCache();

      if (Date.now() - data.timestamp > maxCacheAge) {
        this.productList = await this.fetchAll();
        this.saveToCache(this.productList);
      } else {
        this.productList = this.loadFromCache().productList;
      }
    },
    async fetchAll(): Promise<Product[]> {
      const data = await fetch('https://products.it.fantastiskefroe.dk/')
          .then(value => value.json())
          .then((data: ProductDTO[]) => data);

      return Promise.resolve(data.map(this.toProduct));
    },
    toProduct(source: ProductDTO): Product {
      const variants: Variant[] = Object.values(source.variants)
          .map(variantDTO => {
            return {
              id: variantDTO.id,
              sku: variantDTO.sku,
              inventory: variantDTO.inventory,
            };
          });

      return {
        id: source.id,
        title: source.title,
        url: source.url,
        imgUrl: source.imageUrl,
        variants: variants
      };
    },
    saveToCache(productList: Product[]): void {
      const data = {
        timestamp: Date.now(),
        productList
      };

      window.localStorage.setItem('productList', JSON.stringify(data));
    },
    loadFromCache(): { timestamp: number, productList: Product[] } {
      const data = window.localStorage.getItem('productList');
      if (data === null) {
        return {
          timestamp: 0,
          productList: []
        };
      }

      return JSON.parse(data);
    }
  }
});
</script>

<style scoped>

</style>