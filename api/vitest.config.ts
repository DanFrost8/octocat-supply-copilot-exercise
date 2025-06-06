/// <reference types="vitest" />
import { defineConfig } from 'vitest/config'

export default defineConfig({
	test: {
		globals: false,
		environment: 'node',
		coverage: {
			reporter: ['text', 'json', 'html'],
		},
	},
})