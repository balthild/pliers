import { readonly } from '@vue/reactivity';
import type { Alpine } from 'alpinejs';

export function AlpineComputed(Alpine: Alpine) {
	Alpine.directive('computed', (el, { value, expression }, { effect }) => {
		if (!el.hasAttribute('x-data') || !value) {
			return;
		}

		const $computed = initComputedObject(Alpine, el);

		effect(() => {
			const field = value.toLowerCase().replace(/-[^-]/g, (x) => x[1].toUpperCase());
			const result = Alpine.evaluate(el, expression);
			$computed[field] = result;
		});
	}).before('bind');
}

const computedObjects = new WeakMap();

function initComputedObject(Alpine: Alpine, el: Element) {
	if (computedObjects.has(el)) {
		return computedObjects.get(el);
	}

	const $computed = Alpine.reactive({});
	computedObjects.set(el, $computed);

	Alpine.addScopeToNode(el, {
		$computed: readonly($computed),
	});

	return $computed;
}
