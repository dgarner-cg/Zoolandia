// Theme Toggle
const themeToggle = document.querySelector('.theme-toggle');
const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');

// Check for saved theme preference or use system preference
function getThemePreference() {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        return savedTheme;
    }
    return prefersDarkScheme.matches ? 'dark' : 'light';
}

function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
}

// Initialize theme
setTheme(getThemePreference());

// Toggle theme on button click
themeToggle.addEventListener('click', () => {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
});

// Listen for system theme changes
prefersDarkScheme.addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
        setTheme(e.matches ? 'dark' : 'light');
    }
});

// Mobile Menu
const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
const mobileMenu = document.querySelector('.mobile-menu');

mobileMenuBtn.addEventListener('click', () => {
    mobileMenuBtn.classList.toggle('active');
    mobileMenu.classList.toggle('active');
});

// Close mobile menu when clicking a link
mobileMenu.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        mobileMenuBtn.classList.remove('active');
        mobileMenu.classList.remove('active');
    });
});

// Search Modal
const searchBtn = document.querySelector('.search-btn');
const searchModal = document.getElementById('searchModal');
const searchInput = document.getElementById('searchInput');
const searchResults = document.getElementById('searchResults');

// Sample posts data for search (in production, this would come from an API)
const postsData = [
    {
        title: 'Critical Analysis: Supply Chain Attacks in Modern CI/CD Pipelines',
        category: 'Research',
        excerpt: 'An in-depth examination of attack vectors targeting build systems and dependency management.'
    },
    {
        title: 'Understanding Memory Safety: Buffer Overflow Prevention in Rust',
        category: 'Vulnerabilities',
        excerpt: 'How Rust\'s ownership model eliminates memory vulnerabilities at compile time.'
    },
    {
        title: 'Setting Up a Secure Home Lab for Penetration Testing',
        category: 'Tutorials',
        excerpt: 'A complete guide to building an isolated environment for practicing offensive security.'
    },
    {
        title: 'New NIST Guidelines for Post-Quantum Cryptography Implementation',
        category: 'News',
        excerpt: 'Breaking down the latest recommendations for quantum computing preparation.'
    },
    {
        title: 'Writeup: Binary Exploitation Challenge from DefCon CTF Quals',
        category: 'CTF',
        excerpt: 'A detailed walkthrough of solving "heap_heaven" - a heap exploitation challenge.'
    },
    {
        title: 'API Security: GraphQL Introspection Attacks and Defense',
        category: 'Research',
        excerpt: 'Examining how attackers exploit GraphQL introspection and implementing controls.'
    },
    {
        title: 'OAuth 2.0 Misconfigurations: Common Pitfalls and Exploits',
        category: 'Vulnerabilities',
        excerpt: 'Real-world examples of OAuth implementation flaws leading to account takeover.'
    }
];

function openSearchModal() {
    searchModal.classList.add('active');
    searchInput.focus();
    document.body.style.overflow = 'hidden';
}

function closeSearchModal() {
    searchModal.classList.remove('active');
    searchInput.value = '';
    searchResults.innerHTML = '<p class="search-hint">Start typing to search...</p>';
    document.body.style.overflow = '';
}

if (searchBtn) {
    searchBtn.addEventListener('click', openSearchModal);
}

// Close on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && searchModal.classList.contains('active')) {
        closeSearchModal();
    }
    // Open search with Cmd/Ctrl + K
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        if (searchModal.classList.contains('active')) {
            closeSearchModal();
        } else {
            openSearchModal();
        }
    }
});

// Close on clicking outside
searchModal.addEventListener('click', (e) => {
    if (e.target === searchModal) {
        closeSearchModal();
    }
});

// Search functionality
searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();

    if (query.length === 0) {
        searchResults.innerHTML = '<p class="search-hint">Start typing to search...</p>';
        return;
    }

    const filteredPosts = postsData.filter(post =>
        post.title.toLowerCase().includes(query) ||
        post.category.toLowerCase().includes(query) ||
        post.excerpt.toLowerCase().includes(query)
    );

    if (filteredPosts.length === 0) {
        searchResults.innerHTML = '<p class="search-hint">No results found.</p>';
        return;
    }

    searchResults.innerHTML = filteredPosts.map(post => `
        <div class="search-result-item">
            <h4>${highlightMatch(post.title, query)}</h4>
            <p><span class="post-category">${post.category}</span> ${post.excerpt.substring(0, 80)}...</p>
        </div>
    `).join('');
});

function highlightMatch(text, query) {
    const regex = new RegExp(`(${escapeRegExp(query)})`, 'gi');
    return text.replace(regex, '<mark style="background-color: var(--accent-primary); color: white; padding: 0 2px; border-radius: 2px;">$1</mark>');
}

function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Category Filtering
const categoryTabs = document.querySelectorAll('.category-tab');
const postCards = document.querySelectorAll('.post-card');
const featuredPost = document.querySelector('.featured-post');

categoryTabs.forEach(tab => {
    tab.addEventListener('click', () => {
        // Update active tab
        categoryTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        const category = tab.getAttribute('data-category');

        // Filter posts
        if (category === 'all') {
            postCards.forEach(card => card.classList.remove('hidden'));
            if (featuredPost) featuredPost.classList.remove('hidden');
        } else {
            postCards.forEach(card => {
                const postCategory = card.getAttribute('data-category');
                if (postCategory === category) {
                    card.classList.remove('hidden');
                } else {
                    card.classList.add('hidden');
                }
            });

            // Handle featured post
            if (featuredPost) {
                const featuredCategory = featuredPost.getAttribute('data-category');
                if (featuredCategory === category) {
                    featuredPost.classList.remove('hidden');
                } else {
                    featuredPost.classList.add('hidden');
                }
            }
        }
    });
});

// Newsletter Form
const newsletterForm = document.querySelector('.newsletter-form');

if (newsletterForm) {
    newsletterForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = newsletterForm.querySelector('input[type="email"]').value;

        // In production, this would send to an API
        console.log('Newsletter subscription:', email);

        // Show success message
        const originalContent = newsletterForm.innerHTML;
        newsletterForm.innerHTML = '<p style="color: var(--accent-primary); font-weight: 500;">Thanks for subscribing! Check your inbox.</p>';

        // Reset after 3 seconds
        setTimeout(() => {
            newsletterForm.innerHTML = originalContent;
            // Re-attach event listener would be needed in production
        }, 3000);
    });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href !== '#') {
            e.preventDefault();
            const target = document.querySelector(href);
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        }
    });
});

// Navbar scroll effect
let lastScrollY = window.scrollY;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const currentScrollY = window.scrollY;

    if (currentScrollY > 100) {
        if (currentScrollY > lastScrollY) {
            // Scrolling down
            navbar.style.transform = 'translateY(-100%)';
        } else {
            // Scrolling up
            navbar.style.transform = 'translateY(0)';
        }
    } else {
        navbar.style.transform = 'translateY(0)';
    }

    lastScrollY = currentScrollY;
});

// Add transition for navbar
navbar.style.transition = 'transform 0.3s ease';

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements for animation
document.querySelectorAll('.post-card, .featured-post').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
});

// Load more posts (simulated)
const loadMoreBtn = document.querySelector('.btn-load-more');

if (loadMoreBtn) {
    loadMoreBtn.addEventListener('click', () => {
        loadMoreBtn.textContent = 'Loading...';
        loadMoreBtn.disabled = true;

        // Simulate API call
        setTimeout(() => {
            // In production, this would fetch more posts from an API
            loadMoreBtn.textContent = 'No more posts';
            loadMoreBtn.style.opacity = '0.5';
        }, 1000);
    });
}

// Console easter egg
console.log('%c[hack3r.gg]', 'color: #10a37f; font-size: 24px; font-weight: bold; font-family: monospace;');
console.log('%cWelcome, curious one. 👀', 'color: #888; font-size: 14px;');
console.log('%cInterested in security? Check out our research!', 'color: #888; font-size: 12px;');
