/*!
 * Color mode toggler for Bootstrap's docs (https://getbootstrap.com/)
 * Copyright 2011-2023 The Bootstrap Authors
 * Licensed under the Creative Commons Attribution 3.0 Unported License.
 * Taken from https://getbootstrap.com/docs/5.3/customize/color-modes/#javascript
 */

function getStoredTheme(){
    return localStorage.getItem('theme')
}

function setStoredTheme(theme) {
    localStorage.setItem('theme', theme)
}

function getPreferredTheme() {
    const storedTheme = getStoredTheme()
    if (storedTheme) {
        return storedTheme
    }

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

function setTheme(theme) {
    let currentTheme = theme || 'auto';
    if (theme === 'auto') {
        if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
            currentTheme = 'dark'
        } else {
            currentTheme = 'light'
        }
    }

    const event = new CustomEvent('theme:change', {
        bubbles: true,
        cancelable: false,
        detail: {
            preferredTheme: theme,
            currentTheme: currentTheme,
        }
    })
    document.dispatchEvent(event)
    document.documentElement.setAttribute('data-bs-theme', currentTheme)
    return currentTheme;
}

window.getCurrentTheme = () => {
    return document.documentElement.getAttribute('data-bs-theme') || setTheme(getPreferredTheme());
}

function showActiveTheme(theme, focus = false) {
    const themeSwitcher = document.querySelector('#bd-theme')

    if (!themeSwitcher) {
        return
    }

    const themeSwitcherText = document.querySelector('#bd-theme-text')
    const activeThemeIcon = document.querySelector('.theme-icon-active use')
    const btnToActive = document.querySelector(`[data-bs-theme-value="${theme}"]`)
    const svgOfActiveBtn = btnToActive.querySelector('svg use').getAttribute('href')

    document.querySelectorAll('[data-bs-theme-value]').forEach(element => {
        element.classList.remove('active')
        element.setAttribute('aria-pressed', 'false')
    })

    btnToActive.classList.add('active')
    btnToActive.setAttribute('aria-pressed', 'true')
    activeThemeIcon.setAttribute('href', svgOfActiveBtn)
    const themeSwitcherLabel = `${themeSwitcherText.textContent} (${btnToActive.dataset.bsThemeValue})`
    themeSwitcher.setAttribute('aria-label', themeSwitcherLabel)

    if (focus) {
        themeSwitcher.focus()
    }
}

$(document).on('turbolinks:load', function() {
    setTheme(getPreferredTheme())

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
        const storedTheme = getStoredTheme()
        if (storedTheme !== 'light' && storedTheme !== 'dark') {
            setTheme(getPreferredTheme())
        }
    })

    showActiveTheme(getPreferredTheme())

    document.querySelectorAll('[data-bs-theme-value]')
        .forEach(toggle => {
            toggle.addEventListener('click', () => {
                const theme = toggle.getAttribute('data-bs-theme-value')
                setStoredTheme(theme)
                setTheme(theme)
                showActiveTheme(theme, true)
            })
        })
})
