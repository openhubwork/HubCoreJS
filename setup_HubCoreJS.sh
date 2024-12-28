#!/bin/bash

# نام پوشه پروژه
PROJECT_DIR="HubCoreJS"

# بررسی وجود پوشه پروژه
if [ -d "$PROJECT_DIR" ]; then
    echo "پوشه '$PROJECT_DIR' از قبل وجود دارد. لطفاً نام دیگری انتخاب کنید یا پوشه موجود را حذف کنید."
    exit 1
fi

# ایجاد پوشه پروژه
mkdir "$PROJECT_DIR"
echo "ایجاد پوشه پروژه '$PROJECT_DIR'..."

# ورود به پوشه پروژه
cd "$PROJECT_DIR"

# ایجاد فایل package.json با استفاده از npm init -y با sudo
echo "ایجاد فایل package.json..."
sudo npm init -y

# نصب Express.js و CORS با sudo
echo "نصب Express.js و CORS..."
sudo npm install express cors

# نصب nodemon، livereload، connect-livereload و concurrently به عنوان dev dependencies با sudo
echo "نصب nodemon، livereload، connect-livereload و concurrently..."
sudo npm install --save-dev nodemon livereload connect-livereload concurrently

# بررسی نصب موفقیت‌آمیز پکیج‌ها
if [ $? -ne 0 ]; then
    echo "نصب یکی از پکیج‌ها ناموفق بود."
    exit 1
fi

# ایجاد ساختار فولدرها
mkdir -p public/components/home \
         public/components/about \
         public/components/contact \
         public/components/product \
         public/components/users \
         public/components/menu \
         public/components/header \
         public/components/footer \
         public/css \
         public/images \
         public/js

# ایجاد فایل server.js با استفاده از heredoc و تنظیم پورت به 80
cat << 'EOF' > server.js
const express = require('express');
const path = require('path');
const cors = require('cors');
const livereload = require('livereload');
const connectLivereload = require('connect-livereload');

const app = express();
const PORT = 80; // تنظیم پورت به 80

// راه‌اندازی livereload سرور
const liveReloadServer = livereload.createServer();
liveReloadServer.watch(path.join(__dirname, 'public'));

// راه‌اندازی connect-livereload middleware
app.use(connectLivereload());

// استفاده از CORS
app.use(cors());

// Serve static files از پوشه 'public'
app.use(express.static(path.join(__dirname, 'public')));

// برای هر درخواست GET که با فایل‌های static مطابقت ندارد، فایل index.html را ارسال کن
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// راه‌اندازی سرور
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// بروزرسانی کلاینت‌ها در صورت تغییر فایل‌ها
liveReloadServer.server.once("connection", () => {
    setTimeout(() => {
        liveReloadServer.refresh("/");
    }, 100);
});
EOF

echo "ایجاد فایل 'server.js' با پورت 80 و تنظیمات livereload..."

# ایجاد فایل index.html با استفاده از heredoc
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="fa">
<head>
    <meta charset="UTF-8">
    <title>HubCoreJS - اپلیکیشن تک‌صفحه‌ای با منوی سمت راست</title>
    <link rel="stylesheet" href="/css/styles.css">
    <!-- افزودن استایل‌های هدر و فوتر -->
    <link rel="stylesheet" href="/components/header/style.css">
    <link rel="stylesheet" href="/components/footer/style.css">
</head>
<body>
    <div id="header"></div>
    <div class="main-content">
        <div class="content" id="app">
            <!-- محتوا در اینجا بارگذاری می‌شود -->
        </div>
        <div class="sidebar" id="sidebar">
            <!-- منو در اینجا بارگذاری می‌شود -->
        </div>
    </div>
    <div id="footer"></div>

    <script src="/js/store.js"></script>
    <script src="/js/framework.js"></script>
    <script src="/components/menu/menu.js"></script>
    <script src="/components/header/index.js"></script>
    <script src="/components/footer/index.js"></script>
    <!-- اضافه کردن فایل کامپوننت سفارشی -->
    <script src="/js/hub-tag.js"></script>
</body>
</html>
EOF

echo "ایجاد فایل 'index.html'..."

# ایجاد فایل store.js با استفاده از heredoc
cat << 'EOF' > public/js/store.js
// Store.js - مدیریت وضعیت مرکزی و درخواست‌های API

const Store = (function() {
    let state = {};

    return {
        // دریافت مقدار یک کلید مشخص
        getState: function(key) {
            return state[key];
        },
        // تنظیم مقدار یک کلید مشخص
        setState: function(key, value) {
            state[key] = value;
            console.log(`State updated: ${key} =`, value);
        },
        // دریافت تمام وضعیت‌ها
        getAllState: function() {
            return { ...state };
        },
        // فراخوانی API و ذخیره داده‌ها
        fetchData: async function(url, key) {
            // بررسی اگر داده قبلاً در Store موجود است
            if (this.getState(key)) {
                console.log(`Data for '${key}' already exists in Store.`);
                return this.getState(key);
            }

            try {
                const response = await fetch(url);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                const data = await response.json();
                this.setState(key, data);
                return data;
            } catch (error) {
                console.error('Fetch Error:', error);
                return null;
            }
        }
    };
})();
EOF

echo "ایجاد فایل 'store.js'..."

# ایجاد فایل framework.js با استفاده از heredoc
cat << 'EOF' > public/js/framework.js
// مدیریت روتینگ و بارگذاری محتوای صفحات بدون رفرش
window.navigate = function(event, route) {
    event.preventDefault(); // جلوگیری از رفرش صفحه
    window.history.pushState({}, route, window.location.origin + '/' + route);
    loadPage(route);
}

function loadPage(route) {
    const app = document.getElementById('app');
    // پاک‌سازی محتوای قبلی
    app.innerHTML = '';

    // حذف فایل CSS قبلی اگر وجود دارد
    const oldLink = document.getElementById('component-css');
    if (oldLink) {
        oldLink.remove();
    }

    // بارگذاری فایل CSS مربوطه
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = `/components/${route}/style.css`;
    link.id = 'component-css';
    document.head.appendChild(link);

    // بارگذاری فایل جاوااسکریپت مربوطه
    const script = document.createElement('script');
    script.src = `/components/${route}/index.js`;
    script.onload = () => {
        // پس از بارگذاری اسکریپت، تابع renderPage در آن فراخوانی می‌شود
        if (typeof renderPage === 'function') {
            renderPage(app);
        }
    };
    document.body.appendChild(script);
}

// مدیریت رویداد بازگشت و جلو (back/forward)
window.addEventListener('popstate', () => {
    const path = window.location.pathname.replace('/', '');
    const route = path || 'home';
    loadPage(route);
});

// بارگذاری صفحه اولیه
window.addEventListener('DOMContentLoaded', () => {
    const path = window.location.pathname.replace('/', '');
    const route = path || 'home';
    loadPage(route);
});
EOF

echo "ایجاد فایل 'framework.js'..."

# ایجاد فایل hub-tag.js (تگ سفارشی) با استفاده از heredoc
cat << 'EOF' > public/js/hub-tag.js
class HubTag extends HTMLElement {
  constructor() {
    super();
  }

  connectedCallback() {
    this.innerHTML = `
      <div style="border: 1px solid #ccc; padding: 10px; margin: 10px 0;">
        <h2>Welcome to HubTag Component</h2>
        <p>این یک تگ سفارشی است که می‌توانید در هر قسمتی از پروژه از آن استفاده کنید.</p>
      </div>
    `;
  }
}

customElements.define('hub-tag', HubTag);
EOF

echo "ایجاد فایل 'hub-tag.js'..."

# ایجاد فایل menu.js در فولدر components/menu با استفاده از heredoc
cat << 'EOF' > public/components/menu/menu.js
// مدیریت منو
function loadMenu() {
    const sidebar = document.getElementById('sidebar');
    sidebar.innerHTML = `
        <ul>
            <li><a href="/home" onclick="navigate(event, 'home')">خانه</a></li>
            <li><a href="/about" onclick="navigate(event, 'about')">درباره ما</a></li>
            <li><a href="/contact" onclick="navigate(event, 'contact')">تماس با ما</a></li>
            <li><a href="/product" onclick="navigate(event, 'product')">محصول</a></li>
            <li><a href="/users" onclick="navigate(event, 'users')">کاربران</a></li>
        </ul>
    `;
}

document.addEventListener('DOMContentLoaded', () => {
    loadMenu();
});
EOF

echo "ایجاد فایل 'menu.js' در 'components/menu'..."

# ایجاد فایل menu/style.css با استفاده از heredoc
cat << 'EOF' > public/components/menu/style.css
/* استایل‌های مخصوص منو */
ul {
    list-style: none;
    padding: 0;
}

li {
    margin: 10px 0;
}

a {
    text-decoration: none;
    color: #000;
    display: block;
    padding: 8px;
    border-radius: 4px;
}

a:hover {
    background-color: #ddd;
    color: #333;
}
EOF

echo "ایجاد فایل 'menu/style.css' در 'components/menu'..."

# ایجاد فایل header/index.js با استفاده از heredoc
cat << 'EOF' > public/components/header/index.js
// مدیریت هدر
function renderPageHeader() {
    const header = document.getElementById('header');
    header.innerHTML = `
        <header>
            <div class="logo-container">
                <img src="/images/logo.png" alt="لوگو" class="logo">
            </div>
        </header>
    `;
    console.log("هدر بارگذاری شد.");
}

document.addEventListener('DOMContentLoaded', () => {
    renderPageHeader();
});
EOF

echo "ایجاد فایل 'header/index.js'..."

# ایجاد فایل header/style.css با استفاده از heredoc
cat << 'EOF' > public/components/header/style.css
/* استایل‌های مخصوص هدر */
header {
    background-color: #d0d0d0;
    color: #fff;
    padding: 15px;
    display: flex;
    justify-content: flex-end; /* قرار دادن محتوا در سمت راست */
    align-items: center; /* عمودی وسط‌چین کردن محتوا */
}

.logo-container {
    /* تنظیمات اضافی در صورت نیاز */
}

.logo {
    height: 40px; /* تنظیم ارتفاع لوگو */
}
EOF

echo "ایجاد فایل 'header/style.css'..."

# ایجاد فایل footer/index.js با استفاده از heredoc
cat << 'EOF' > public/components/footer/index.js
// مدیریت فوتر
function renderPageFooter() {
    const footer = document.getElementById('footer');
    footer.innerHTML = `
        <footer>
            <p>&copy; 2024 تمامی حقوق محفوظ است.</p>
        </footer>
    `;
    console.log("فوتر بارگذاری شد.");
}

document.addEventListener('DOMContentLoaded', () => {
    renderPageFooter();
});
EOF

echo "ایجاد فایل 'footer/index.js'..."

# ایجاد فایل footer/style.css با استفاده از heredoc
cat << 'EOF' > public/components/footer/style.css
/* استایل‌های مخصوص فوتر */
footer {
    background-color: #333;
    color: #fff;
    padding: 10px;
    text-align: center;
    position: fixed;
    bottom: 0;
    width: 100%;
}
EOF

echo "ایجاد فایل 'footer/style.css'..."

# ایجاد فایل home/index.js با استفاده از heredoc
cat << 'EOF' > public/components/home/index.js
function renderPage(app) {
    // تنظیم وضعیت فعلی به 'home'
    Store.setState('currentPage', 'home');

    app.innerHTML = `
        <h1>Home Dashboard</h1>
        <p>ما یک تیم توسعه‌دهنده هستیم که در حال ساخت فریم‌ورک‌های فرانت‌اند هستیم.</p>
        <p>صفحه فعلی: ${Store.getState('currentPage')}</p>
        <!-- استفاده از تگ سفارشی در صفحه خانه -->
        <hub-tag></hub-tag>
    `;
    console.log("صفحه خانه بارگذاری شد.");
}
EOF

echo "ایجاد فایل 'home/index.js'..."

# ایجاد فایل home/style.css با استفاده از heredoc
cat << 'EOF' > public/components/home/style.css
/* استایل‌های مخصوص صفحه خانه */
h1 {
    color: blue;
}

#product {
    margin-top: 20px;
}

#product img {
    display: block;
    margin-bottom: 10px;
}
EOF

echo "ایجاد فایل 'home/style.css'..."

# ایجاد فایل about/index.js با استفاده از heredoc
cat << 'EOF' > public/components/about/index.js
function renderPage(app) {
    // تنظیم وضعیت فعلی به 'about'
    Store.setState('currentPage', 'about');

    app.innerHTML = `
        <h1>درباره ما</h1>
        <p>ما یک تیم توسعه‌دهنده هستیم که در حال ساخت فریم‌ورک‌های فرانت‌اند هستیم.</p>
        <p>صفحه فعلی: ${Store.getState('currentPage')}</p>
    `;
    console.log("صفحه درباره ما بارگذاری شد.");
}
EOF

echo "ایجاد فایل 'about/index.js'..."

# ایجاد فایل about/style.css با استفاده از heredoc
cat << 'EOF' > public/components/about/style.css
/* استایل‌های مخصوص صفحه درباره ما */
h1 {
    color: green;
}
EOF

echo "ایجاد فایل 'about/style.css'..."

# ایجاد فایل contact/index.js با استفاده از heredoc
cat << 'EOF' > public/components/contact/index.js
function renderPage(app) {
    // تنظیم وضعیت فعلی به 'contact'
    Store.setState('currentPage', 'contact');

    app.innerHTML = `
        <h1>تماس با ما</h1>
        <p>برای ارتباط با ما از طریق ایمیل contact@example.com اقدام کنید.</p>
        <p>صفحه فعلی: ${Store.getState('currentPage')}</p>
    `;
    console.log("صفحه تماس با ما بارگذاری شد.");
}
EOF

echo "ایجاد فایل 'contact/index.js'..."

# ایجاد فایل contact/style.css با استفاده از heredoc
cat << 'EOF' > public/components/contact/style.css
/* استایل‌های مخصوص صفحه تماس با ما */
h1 {
    color: red;
}
EOF

echo "ایجاد فایل 'contact/style.css'..."

# ایجاد فایل product/index.js با استفاده از heredoc
cat << 'EOF' > public/components/product/index.js
function renderPage(app) {
    // تنظیم وضعیت فعلی به 'product'
    Store.setState('currentPage', 'product');

    // بررسی اگر داده محصول در Store موجود است
    const productData = Store.getState('productData');

    app.innerHTML = `
        <h1>محصول</h1>
        <div id="product-details"></div>
    `;
    console.log("صفحه محصول بارگذاری شد.");

    if (productData) {
        console.log("داده محصول از Store دریافت شد.");
        displayProduct(productData);
    } else {
        // فراخوانی API و نمایش داده‌ها
        Store.fetchData('https://fakestoreapi.com/products/1', 'productData').then(data => {
            if (data) {
                displayProduct(data);
            } else {
                app.innerHTML += `<p>خطا در دریافت داده‌ها.</p>`;
            }
        });
    }
}

function displayProduct(data) {
    const productDiv = document.getElementById('product-details');
    productDiv.innerHTML = `
        <h2>${data.title}</h2>
        <img src="${data.image}" alt="${data.title}" style="width:200px;">
        <p><strong>قیمت:</strong> $${data.price}</p>
        <p><strong>توضیحات:</strong> ${data.description}</p>
        <p><strong>دسته‌بندی:</strong> ${data.category}</p>
        <p><strong>رتبه‌بندی:</strong> ${data.rating.rate} از 5 (${data.rating.count} نظرات)</p>
    `;
}
EOF

echo "ایجاد فایل 'product/index.js'..."

# ایجاد فایل product/style.css با استفاده از heredoc
cat << 'EOF' > public/components/product/style.css
/* استایل‌های مخصوص صفحه محصول */
h1 {
    color: purple;
}

#product-details {
    margin-top: 20px;
}

#product-details img {
    display: block;
    margin-bottom: 10px;
}
EOF

echo "ایجاد فایل 'product/style.css'..."

# ایجاد فایل users/index.js با استفاده از heredoc
cat << 'EOF' > public/components/users/index.js
function renderPage(app) {
    // تنظیم وضعیت فعلی به 'users'
    Store.setState('currentPage', 'users');

    // بررسی اگر داده کاربران در Store موجود است
    const usersData = Store.getState('usersData');

    app.innerHTML = `
        <h1>لیست کاربران</h1>
        <div id="users-list"></div>
    `;
    console.log("صفحه کاربران بارگذاری شد.");

    if (usersData) {
        console.log("داده کاربران از Store دریافت شد.");
        displayUsers(usersData);
    } else {
        // فراخوانی API و نمایش داده‌ها
        Store.fetchData('https://fakestoreapi.com/users', 'usersData').then(data => {
            if (data) {
                displayUsers(data);
            } else {
                app.innerHTML += `<p>خطا در دریافت داده‌ها.</p>`;
            }
        });
    }
}

function displayUsers(users) {
    const usersListDiv = document.getElementById('users-list');
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>نام کاربری</th>
                    <th>نام</th>
                    <th>ایمیل</th>
                    <th>شهر</th>
                    <th>تلفن</th>
                </tr>
            </thead>
            <tbody>
    `;

    users.forEach(user => {
        html += `
            <tr>
                <td>${user.id}</td>
                <td>${user.username}</td>
                <td>${user.name.firstname} ${user.name.lastname}</td>
                <td>${user.email}</td>
                <td>${user.address.city}</td>
                <td>${user.phone}</td>
            </tr>
        `;
    });

    html += `
            </tbody>
        </table>
    `;

    usersListDiv.innerHTML = html;
}
EOF

echo "ایجاد فایل 'users/index.js'..."

# ایجاد فایل users/style.css با استفاده از heredoc
cat << 'EOF' > public/components/users/style.css
/* استایل‌های مخصوص صفحه کاربران */
h1 {
    color: teal;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}

th, td {
    border: 1px solid #ccc;
    padding: 10px;
    text-align: left;
}

th {
    background-color: #f4f4f4;
}

tr:nth-child(even) {
    background-color: #f9f9f9;
}
EOF

echo "ایجاد فایل 'users/style.css'..."

# ایجاد فایل CSS اصلی با استفاده از heredoc
cat << 'EOF' > public/css/styles.css
/* استایل‌های مشترک برای تمامی صفحات */
body {
    display: flex;
    flex-direction: column;
    margin: 0;
    font-family: Arial, sans-serif;
    min-height: 100vh;
}

.main-content {
    display: flex;
    flex: 1;
}

.sidebar {
    width: 200px;
    background-color: #f4f4f4;
    padding: 10px;
    border-left: 1px solid #ccc;
    box-sizing: border-box;
}

.sidebar ul {
    list-style: none;
    padding: 0;
}

.sidebar li {
    margin: 10px 0;
    padding: 8px;
    border-radius: 4px;
}

.sidebar li:hover {
    background-color: #ddd;
}

.sidebar a {
    text-decoration: none;
    color: #000;
    display: block;
}

.sidebar a:hover {
    color: #333;
}

.content {
    flex: 1;
    padding: 20px;
    margin-bottom: 50px; /* فضای مناسب برای فوتر */
}

/* تنظیمات فوتر */
#footer {
    /* فوتر به طور ثابت در پایین صفحه قرار می‌گیرد */
}
EOF

echo "ایجاد فایل 'styles.css'..."

# اصلاح اسکریپت start در package.json به استفاده از nodemon و livereload با connect-livereload با sudo
echo "تنظیم اسکریپت 'start' در 'package.json'..."
sudo npm set-script start "concurrently \"sudo nodemon server.js\" \"sudo livereload public --ext html css js\""

echo "تنظیم اسکریپت 'start' به استفاده از nodemon و livereload..."

# نصب پکیج concurrently به عنوان dev dependency (در صورتی که قبلاً نصب نشده باشد) با sudo
sudo npm install --save-dev concurrently

# ایجاد پوشه تصاویر و افزودن پیام برای قرار دادن لوگو
mkdir -p public/images
echo "لطفاً فایل لوگو (مثلاً logo.png) را در پوشه 'public/images/' قرار دهید."

# پایان اسکریپت
echo "پروژه '$PROJECT_DIR' با موفقیت ایجاد شد."
echo "لطفاً یک فایل لوگو (مثلاً logo.png) را در پوشه 'public/images/' قرار دهید."
echo "برای اجرای سرور، به پوشه '$PROJECT_DIR' بروید و دستور 'sudo npm start' را اجرا کنید."
echo "سپس مرورگر شما به صورت خودکار به آدرس http://localhost باز خواهد شد."
echo "برای مشاهده صفحات مختلف، از منو لینک‌های 'خانه', 'درباره ما', 'تماس با ما', 'محصول', و 'کاربران' را انتخاب کنید."
echo "در هر جای صفحه هم برای تست، می‌توانید به سادگی از تگ سفارشی <hub-tag></hub-tag> استفاده کنید."
