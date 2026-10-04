import AlpineFocus from '@alpinejs/focus';
import AlpinePersist from '@alpinejs/persist';
import Alpine from 'alpinejs';

declare global {
	var Alpine: Alpine.Alpine;
	var $: (selector: string) => any;
}

globalThis.Alpine = Alpine;

window.$ = (selector: string) => {
	const element = document.querySelector(selector);
	if (false === element instanceof HTMLElement) {
		throw new Error(`Element not found or invalid: ${selector}`);
	}

	return Alpine.$data(element);
};

Alpine.plugin(AlpineFocus);
Alpine.plugin(AlpinePersist);
Alpine.plugin(AlpineHistory);
Alpine.start();

function AlpineHistory(Alpine: Alpine.Alpine) {
	const timings = performance.getEntriesByType('navigation');
	// @ts-expect-error
	const restoring = timings[0]?.type === 'back_forward';

	// TODO: put only a random id in history state. store actual data in sessionStorage
	const storage = {
		getItem: (key: string) => {
			if (!restoring) return null;
			return history.state?.pliers?.[key] ?? null;
		},
		setItem: (key: string, value: unknown) => {
			const state = history.state ?? {};
			state.pliers ??= {};
			state.pliers[key] = value;

			history.replaceState(state, '');
		},
	};

	Alpine.magic('history', () => {
		return <T>(subject: T) => Alpine.$persist(subject).using(storage);
	});
}
