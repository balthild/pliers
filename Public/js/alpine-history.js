const timings = performance.getEntriesByType('navigation');
const restoring = timings[0]?.type === 'back_forward';

document.addEventListener('alpine:init', () => {
	// TODO: put only a random id in history state. store actual data in sessionStorage
	const storage = {
		getItem: (key) => {
			if (!restoring) return null;
			return history.state?.pliers?.[key] ?? null;
		},
		setItem: (key, value) => {
			const state = history.state ?? {};
			state.pliers ??= {};
			state.pliers[key] = value;

			history.replaceState(state, '');
		},
	};

	Alpine.magic('history', () => {
		return (subject) => Alpine.$persist(subject).using(storage);
	});
});
