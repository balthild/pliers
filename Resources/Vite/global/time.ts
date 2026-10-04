document.addEventListener('DOMContentLoaded', () => {
	document.querySelectorAll<HTMLTimeElement>('time[data-render]').forEach((el) => {
		const date = new Date(el.dateTime);

		switch (el.dataset.render) {
			case 'iso':
				el.textContent = date.toISOString();
				break;

			case 'full':
				el.textContent = date.toLocaleString();
				break;

			case 'date':
				el.textContent = date.toLocaleDateString();
				break;

			case 'time':
				el.textContent = date.toLocaleTimeString();
				break;
		}
	});
});
