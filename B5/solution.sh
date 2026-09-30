#!/usr/bin/env bash
# ==============================================================================
# BÀI 5: QUẢN LÝ QUYỀN SỞ HỮU THƯ MỤC WEB (DIRECTORY PERMISSION MANAGEMENT)
# ==============================================================================

set -e

echo "=== [1/4] Chuẩn bị môi trường (Mô phỏng trạng thái ban đầu của đề bài) ==="

# 1. Tạo user devops nếu chưa tồn tại
if ! id "devops" &>/dev/null; then
    echo ">> Tạo user 'devops'..."
    sudo useradd -m -s /bin/bash devops
fi

# 2. Đảm bảo nhóm www-data tồn tại (nhóm mặc định của Nginx/Apache trên Debian/Ubuntu)
if ! getent group www-data &>/dev/null; then
    echo ">> Tạo group 'www-data'..."
    sudo groupadd www-data
fi

# 3. Tạo thư mục web và file mẫu ban đầu với quyền sở hữu của root
echo ">> Khởi tạo thư mục /var/www/ptit-web/html và file index.html thuộc quyền root..."
sudo mkdir -p /var/www/ptit-web/html
sudo bash -c 'cat << "EOF" > /var/www/ptit-web/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>PTIT Web Service</title>
</head>
<body>
    <h1>Welcome to PTIT Web!</h1>
</body>
</html>
EOF'

# Đặt ban đầu thuộc root:root để mô phỏng đúng bối cảnh đề bài
sudo chown -R root:root /var/www/ptit-web
sudo chmod -R 755 /var/www/ptit-web

echo ">> Trạng thái ban đầu:"
ls -ld /var/www/ptit-web
ls -la /var/www/ptit-web/html/index.html


echo ""
echo "=== [2/4] Thực hiện yêu cầu của đề bài ==="

# Yêu cầu 1: Đổi chủ sở hữu (owner) sang 'devops' và nhóm sở hữu (group) sang 'www-data'
echo ">> Đổi owner sang 'devops' và group sang 'www-data' đệ quy (-R)..."
sudo chown -R devops:www-data /var/www/ptit-web

# Yêu cầu 2: Phân quyền chmod
# - Thư mục: 750 (devops: rwx, www-data: r-x, others: ---)
#   Lưu ý: Group www-data cần quyền 'x' trên thư mục để Nginx duyệt vào đọc file, tránh lỗi 403 Forbidden.
# - Tệp tin: 640 (devops: rw-, www-data: r--, others: ---)
#   devops có quyền ghi (w) để cập nhật code mà không cần sudo; www-data chỉ có quyền đọc (r).
echo ">> Phân quyền thư mục (750) và file (640)..."
sudo find /var/www/ptit-web -type d -exec chmod 750 {} +
sudo find /var/www/ptit-web -type f -exec chmod 640 {} +


echo ""
echo "=== [3/4] Kiểm tra kết quả phân quyền ==="

echo ">> 1. Kiểm tra quyền của thư mục /var/www/ptit-web/:"
ls -la /var/www/ptit-web/

echo ""
echo ">> 2. Kiểm tra quyền của thư mục con và file bên trong:"
ls -la /var/www/ptit-web/html/


echo ""
echo "=== [4/4] Kiểm thử thao tác chỉnh sửa file bằng user devops (không dùng sudo) ==="

# Thử nghiệm chỉnh sửa file index.html dưới quyền user devops
sudo -u devops bash -c 'echo "<!-- Update: Deploy new version $(date) -->" >> /var/www/ptit-web/html/index.html'

if [ $? -eq 0 ]; then
    echo ">> [THÀNH CÔNG] User devops đã ghi đè / chỉnh sửa file index.html thành công mà không cần sudo!"
else
    echo ">> [THẤT BẠI] User devops không thể ghi file!"
    exit 1
fi

echo ""
echo ">> Nội dung cuối file /var/www/ptit-web/html/index.html:"
tail -n 3 /var/www/ptit-web/html/index.html

echo ""
echo ">> [HOÀN THÀNH BÀI TẬP]"
