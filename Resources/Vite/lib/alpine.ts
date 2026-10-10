import type { Alpine } from 'alpinejs';

export function AlpineHistory(Alpine: Alpine) {
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
