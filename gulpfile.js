const gulp = require('gulp');
const fs = require('fs');
const replace = require('gulp-replace');
const zip = require('gulp-zip');
const dateTime = require('node-datetime');
const packageInfo = require('./package.json');

const buildDir = 'build/';
const distDir = 'dist/';

// Read version from package.json
const version = packageInfo.version;
const pluginName = 'koha-plugin-razorpay-v' + version;
const releaseFileName = pluginName + '.kpz';

// Get current date for date_updated
function getCurrentDate() {
    const dt = dateTime.create();
    return dt.format('Y-m-d');
}

// Clean build directory
function clean() {
    if (fs.existsSync(buildDir)) {
        fs.rmSync(buildDir, { recursive: true, force: true });
    }
    if (fs.existsSync(distDir)) {
        fs.rmSync(distDir, { recursive: true, force: true });
    }
    fs.mkdirSync(buildDir, { recursive: true });
    fs.mkdirSync(distDir, { recursive: true });
    return Promise.resolve();
}

// Copy plugin files to build directory
function copyFiles() {
    return gulp.src([
        'Koha/**/*'
    ])
    .pipe(gulp.dest(buildDir + 'Koha/'));
}

// Replace version and date placeholders
function replaceVersions() {
    const currentDate = getCurrentDate();
    
    return gulp.src(buildDir + 'Koha/**/*.pm')
        .pipe(replace('{VERSION}', version))
        .pipe(replace('1970-01-01', currentDate))
        .pipe(gulp.dest(buildDir + 'Koha/'));
}

// Create .kpz (zip) file
function createKPZ() {
    return gulp.src(buildDir + '**/*')
        .pipe(zip(releaseFileName))
        .pipe(gulp.dest(distDir));
}

// Build task
const build = gulp.series(
    clean,
    copyFiles,
    replaceVersions,
    createKPZ
);

// Default task
exports.default = build;
exports.build = build;
exports.clean = clean;

// Release task (same as build for now)
exports.release = build;
