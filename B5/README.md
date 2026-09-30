# HƯỚNG DẪN GIẢI BÀI 5: QUẢN LÝ QUYỀN SỞ HỮU THƯ MỤC WEB (DIRECTORY PERMISSION MANAGEMENT)

## 1. Phân tích yêu cầu đề bài

* **Bối cảnh:**
  Thư mục `/var/www/ptit-web/` ban đầu thuộc quyền sở hữu của `root:root`, khiến user `devops` không thể sửa đổi file mã nguồn trực tiếp (phải dùng `sudo`, vi phạm nguyên tắc bảo mật tối thiểu).
* **Ràng buộc:**
  1. Thay đổi chủ sở hữu (owner) thư mục và nội dung con sang `devops`.
  2. Thay đổi nhóm sở hữu (group) sang `www-data` (nhóm chạy của Nginx).
  3. Thiết lập quyền truy cập (chmod):
     * Chủ sở hữu (`devops`): Đọc và Ghi (`r` và `w`, đối với thư mục cần cả `x` để duyệt).
     * Nhóm sở hữu (`www-data`): Chỉ đọc (`r`, đối với thư mục cần cả `x` để Nginx truy cập đọc file).
     * Người khác (`others`): Không có quyền (`---`) hoặc chỉ đọc.
  4. Đảm bảo Nginx không gặp lỗi **403 Forbidden** khi phục vụ trang web.
* **Kiểm tra:**
  * Lệnh `ls -la /var/www/ptit-web/` hiển thị đúng owner `devops`, group `www-data`.
  * User `devops` chạy `echo "Update" >> /var/www/ptit-web/html/index.html` thành công không cần `sudo`.
  * Truy cập Nginx trả về `200 OK` hiển thị nội dung mới, không bị `403 Forbidden`.

---

## 2. Các câu lệnh thực hiện chính

### Bước 1: Thay đổi quyền sở hữu (Owner & Group)
Sử dụng lệnh `chown` với cờ `-R` (Recursive - áp dụng đệ quy cho toàn bộ thư mục và file bên trong):

```bash
sudo chown -R devops:www-data /var/www/ptit-web
```

* `devops`: Chỉ định User sở hữu (Owner).
* `www-data`: Chỉ định Group sở hữu.
* `-R`: Thay đổi đệ quy từ `/var/www/ptit-web` vào tất cả các thư mục con và file.

---

### Bước 2: Thiết lập quyền truy cập tối ưu (Chmod)

> **Lưu ý quan trọng về lỗi 403 Forbidden của Nginx:**
> * Đối với **thư mục (directory)**, Linux yêu cầu quyền thực thi (`x` - execute) thì tiến trình Nginx (chạy dưới group `www-data`) mới có thể duyệt (traverse/cd) vào trong để đọc các file con. Nếu thư mục chỉ có quyền đọc (`r`) mà thiếu `x`, Nginx sẽ báo lỗi **403 Forbidden**.
> * Đối với **tệp tin (file)** thông thường (HTML, CSS, JS), không được cấp quyền `x` để đảm bảo an toàn bảo mật.

#### Cách 1: Sử dụng lệnh `find` (Chuẩn xác và phổ biến nhất)
* **Quyền cho thư mục:** `750` (`rwxr-x---`)
  * Owner (`devops`): `rwx` (7) – Toàn quyền đọc, ghi, duyệt thư mục.
  * Group (`www-data`): `r-x` (5) – Đọc và duyệt thư mục (giúp Nginx đọc được file bên trong).
  * Others: `---` (0) – Không có quyền truy cập.
* **Quyền cho tệp tin:** `640` (`rw-r-----`)
  * Owner (`devops`): `rw-` (6) – Đọc và ghi (chỉnh sửa file không cần sudo).
  * Group (`www-data`): `r--` (4) – Chỉ đọc nội dung file để serve web.
  * Others: `---` (0) – Không có quyền truy cập.

Lệnh thực thi:
```bash
# Phân quyền cho tất cả thư mục
sudo find /var/www/ptit-web -type d -exec chmod 750 {} +

# Phân quyền cho tất cả file
sudo find /var/www/ptit-web -type f -exec chmod 640 {} +
```

*(Ghi chú: Nếu muốn người dùng khác trên hệ thống cũng có thể đọc nội dung, bạn có thể dùng `755` cho thư mục và `644` cho tệp tin).*

#### Cách 2: Sử dụng ký hiệu viết tắt với `X` lớn (Execute conditionally)
Ký tự `X` hoa chỉ cấp quyền thực thi cho thư mục hoặc các file vốn đã có quyền thực thi:
```bash
sudo chmod -R u=rwX,g=rX,o= /var/www/ptit-web
```
Lệnh trên tự động gán:
* Thư mục: `u=rwx`, `g=r-x`, `o=---` (tương đương `750`)
* File: `u=rw-`, `g=r--`, `o=---` (tương đương `640`)

---

## 3. Các bước kiểm tra kết quả

### 1. Kiểm tra phân quyền thư mục và file:
```bash
ls -la /var/www/ptit-web/
ls -la /var/www/ptit-web/html/
```
* **Kết quả mong đợi:** 
  * Cột owner là `devops`, group là `www-data`.
  * Quyền thư mục hiển thị `drwxr-x---` (hoặc `drwxr-xr-x`).
  * Quyền file `index.html` hiển thị `-rw-r-----` (hoặc `-rw-r--r--`).

### 2. Kiểm tra quyền ghi của user `devops` (không dùng sudo):
Chuyển sang user `devops` hoặc chạy lệnh dưới danh nghĩa user `devops`:
```bash
su - devops
echo "Update" >> /var/www/ptit-web/html/index.html
```
Hoặc test nhanh bằng `sudo -u devops`:
```bash
sudo -u devops bash -c 'echo "Update" >> /var/www/ptit-web/html/index.html'
```
* **Kết quả mong đợi:** Lệnh thực thi thành công, không báo lỗi `Permission denied`.

### 3. Kiểm tra web Nginx:
```bash
curl -i http://localhost/
```
* **Kết quả mong đợi:**
  * HTTP status: `200 OK` (không bị `403 Forbidden`).
  * Nội dung trả về có chứa từ `"Update"` vừa thêm vào.

---

## 4. Kịch bản chạy toàn diện (Setup mô phỏng + Thực hiện + Test)

Nếu đang thực hành trên máy ảo Ubuntu / WSL, bạn có thể thực hiện theo script `solution.sh` đính kèm trong thư mục này.
