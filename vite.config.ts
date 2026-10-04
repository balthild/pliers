import fs from 'node:fs';
import path from 'node:path';

import tailwindcss from '@tailwindcss/vite';
import { defineConfig, Plugin } from 'vite';

export default defineConfig(({ command }) => ({
	// In dev the browser interacts with the Vite dev server directly, so assets
	// live at the server root. In release they are served by Vapor under /dist/.
	base: command === 'serve' ? '/' : '/dist/',
	root: 'Resources/Vite',
	input: 'main.js',
	plugins: [tailwindcss(), devServerAddress()],
	resolve: {
		tsconfigPaths: true,
	},
	build: {
		outDir: '../../Public/dist',
		emptyOutDir: true,
		manifest: true,
	},
	clearScreen: false,
}));

function devServerAddress(): Plugin {
	let file: string;

	return {
		name: 'vite-dev-server-address',

		configResolved(config) {
			file = path.resolve(config.root, config.build.outDir, '.vite/dev');
		},

		configureServer(server) {
			server.httpServer?.on('listening', () => {
				const address = server.httpServer!.address();

				const proto = server.config.server.https ? 'https' : 'http';
				const host = server.config.server.host || 'localhost';
				const port = typeof address === 'string' ? '' : address?.port;

				const url = `${proto}://${host}:${port}`;

				fs.writeFileSync(file, url);
			});
		},

		buildStart() {
			if (!globalThis.devServerAddressCleanupHook) {
				process.on('SIGINT', () => process.exit());
				process.on('SIGTERM', () => process.exit());
				process.on('SIGHUP', () => process.exit());

				globalThis.devServerAddressCleanupHook = new Set();
			}

			if (!globalThis.devServerAddressCleanupHook.has(file)) {
				process.on('exit', () => {
					fs.rmSync(file, { force: true });
				});

				globalThis.devServerAddressCleanupHook.add(file);
			}
		},
	};
}

declare global {
	var devServerAddressCleanupHook: Set<string>;
}
