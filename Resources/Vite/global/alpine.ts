import AlpineFocus from '@alpinejs/focus';
import AlpinePersist from '@alpinejs/persist';
import Alpine from 'alpinejs';

import { AlpineComputed } from '#/lib/alpine/computed';
import { AlpineHistory } from '#/lib/alpine/history';

declare global {
	interface Window {
		$: (selector: string) => any;
		Alpine: Alpine.Alpine;
	}
}

window.$ = (selector: string) => {
	const element = document.querySelector(selector);
	if (false === element instanceof HTMLElement) {
		throw new Error(`Element not found or invalid: ${selector}`);
	}

	return Alpine.$data(element);
};

window.Alpine = Alpine;

Alpine.plugin(AlpineFocus);
Alpine.plugin(AlpinePersist);
Alpine.plugin(AlpineComputed);
Alpine.plugin(AlpineHistory);
Alpine.start();
