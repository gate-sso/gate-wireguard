# Dark Mode Implementation

This document describes the dark mode feature added to the Gate WireGuard application.

## Features

- **Toggle Button**: A floating toggle button in the top-right corner of every page
- **Persistent Preference**: User's dark mode preference is saved in localStorage
- **System Preference Detection**: Automatically detects user's system preference on first visit
- **Smooth Transitions**: 0.3s transitions when switching between light and dark modes
- **Bootstrap Integration**: Uses Bootstrap's dark mode system with custom CSS variables

## How to Use

1. **Toggle Dark Mode**: Click the floating moon/sun icon in the top-right corner
2. **Automatic Detection**: On first visit, the app detects your system preference
3. **Persistence**: Your choice is remembered for future visits

## Technical Implementation

### Files Modified/Created

1. **CSS Styles**: `app/assets/stylesheets/application.bootstrap.scss`
   - Dark mode CSS variables
   - Component-specific dark mode styles
   - Transition animations

2. **JavaScript Controller**: `app/javascript/controllers/dark_mode_controller.js`
   - Handles toggle functionality
   - Manages localStorage persistence
   - Updates UI icons

3. **Layout Updates**:
   - `app/views/layouts/application.html.erb`
   - `app/views/layouts/admin.html.erb`
   - Added Stimulus controller and toggle button

4. **Partials**:
   - `app/views/shared/_dark_mode_toggle.html.erb` - Reusable toggle button
   - `app/views/shared/_navbar.html.erb` - Updated for dark mode compatibility

### CSS Variables Used

The implementation uses CSS custom properties for easy theming:

**Light Mode Variables:**
- `--bs-body-bg`: #ffffff
- `--bs-body-color`: #212529
- `--card-bg`: #ffffff
- `--nav-bg`: #ffffff
- etc.

**Dark Mode Variables:**
- `--bs-body-bg`: #1a1a1a
- `--bs-body-color`: #e9ecef
- `--card-bg`: #2d3748
- `--nav-bg`: #2d3748
- etc.

### JavaScript Functionality

The Stimulus controller handles:
- Theme detection and switching
- localStorage persistence
- Icon updates (moon/sun)
- Bootstrap theme attribute management

## Browser Compatibility

- All modern browsers that support CSS custom properties
- localStorage for preference persistence
- CSS transitions for smooth mode switching

## Color Scheme

### Light Mode
- Background: White (#ffffff)
- Text: Dark gray (#212529)
- Cards: White with light borders
- Primary: Bootstrap blue (#0d6efd)

### Dark Mode
- Background: Dark gray (#1a1a1a)
- Text: Light gray (#e9ecef)
- Cards: Dark blue-gray (#2d3748)
- Primary: Bright blue (#6ea8fe)

## Accessibility

- High contrast ratios maintained in both modes
- Proper focus states for the toggle button
- Screen reader friendly button titles
- Smooth transitions that respect prefers-reduced-motion

## Future Enhancements

Potential improvements:
- Per-user preference stored in database
- Additional color themes (e.g., blue, green)
- Automatic scheduling (dark mode at night)
- Better mobile responsiveness for toggle button
