let persisted = false;

window.addEventListener('pageshow', (event) => {
	if (event.persisted) {
		persisted = true;
		return;
	}

	const state = history.state ?? {};
	if (state.pliers) {
		delete state.pliers;
		history.replaceState(state, '');
	}
});

document.addEventListener('alpine:init', () => {
	const storage = {
		getItem: (key) => {
			if (!persisted) return null;
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
