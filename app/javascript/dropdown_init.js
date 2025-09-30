// Dropdown initialization
console.log('Dropdown init script loaded');

// Import Bootstrap and make it globally available
import * as bootstrap from "bootstrap"
import * as Popper from "@popperjs/core"

// Make Bootstrap and Popper available globally
window.bootstrap = bootstrap;
window.Popper = Popper;

console.log('Bootstrap made globally available:', window.bootstrap);
console.log('Popper made globally available:', window.Popper);

function initializeDropdowns() {
    console.log('Initializing dropdowns...');
    console.log('Bootstrap available:', typeof bootstrap !== 'undefined');

    const dropdownElements = document.querySelectorAll('[data-bs-toggle="dropdown"]');
    console.log('Found dropdown elements:', dropdownElements.length);

    if (dropdownElements.length === 0) {
        console.log('No dropdown elements found');
        return;
    }

    let bootstrapWorking = false;

    // Try Bootstrap initialization
    if (typeof bootstrap !== 'undefined' && bootstrap.Dropdown) {
        console.log('Trying Bootstrap initialization...');
        dropdownElements.forEach((element, index) => {
            try {
                new bootstrap.Dropdown(element);
                console.log(`Bootstrap dropdown ${index} initialized`);
                bootstrapWorking = true;
            } catch (error) {
                console.error(`Bootstrap dropdown ${index} failed:`, error);
            }
        });
    }

    // Fallback to manual implementation
    if (!bootstrapWorking) {
        console.log('Using manual dropdown implementation...');
        dropdownElements.forEach((element, index) => {
            console.log(`Setting up manual dropdown ${index}`);

            element.addEventListener('click', function (e) {
                console.log('Dropdown clicked');
                e.preventDefault();
                e.stopPropagation();

                const menu = this.nextElementSibling;
                if (menu && menu.classList.contains('dropdown-menu')) {
                    // Close other dropdowns
                    document.querySelectorAll('.dropdown-menu.show').forEach(otherMenu => {
                        if (otherMenu !== menu) {
                            otherMenu.classList.remove('show');
                        }
                    });

                    // Toggle this dropdown
                    menu.classList.toggle('show');
                    console.log('Dropdown toggled, now showing:', menu.classList.contains('show'));
                } else {
                    console.log('Menu not found or not dropdown-menu');
                }
            });
        });

        // Close dropdowns when clicking outside
        document.addEventListener('click', function (e) {
            if (!e.target.closest('.dropdown')) {
                document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
                    menu.classList.remove('show');
                    console.log('Closed dropdown from outside click');
                });
            }
        });
    }
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDropdowns);
} else {
    initializeDropdowns();
}

// Re-initialize on Turbo navigation
document.addEventListener('turbo:load', initializeDropdowns);
document.addEventListener('turbo:render', initializeDropdowns);
