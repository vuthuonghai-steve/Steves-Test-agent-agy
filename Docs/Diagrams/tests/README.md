# 📊 Luồng Tương Tác Người Dùng Với Giao Diện Người Dùng (User - UI Interaction Flow)

Diagram được thiết kế chuyên biệt để mô hình hóa toàn diện chu trình tương tác giữa Người dùng và Giao diện ứng dụng (Frontend), bao gồm phân tầng xử lý logic Client và trao đổi dữ liệu với Máy chủ (Backend).

---

## 📁 Danh Sách Tệp Trong Thư Mục

- [`user-ui-interaction-flow.drawio`](file:///home/stveve/Documents/workspace/Steve/Steves-Test-agent-agy/Docs/Diagrams/tests/user-ui-interaction-flow.drawio): Tệp định dạng chuẩn Draw.io (mxGraphModel XML). Có thể mở và chỉnh sửa trên desktop hoặc Diagrams.net.
- [`user-ui-interaction-flow.svg`](file:///home/stveve/Documents/workspace/Steve/Steves-Test-agent-agy/Docs/Diagrams/tests/user-ui-interaction-flow.svg): Tệp Vector SVG chất lượng cao, hiển thị trực quan ngay lập tức trên mọi trình duyệt, IDE và Markdown preview.
- [`open-in-browser-url.txt`](file:///home/stveve/Documents/workspace/Steve/Steves-Test-agent-agy/Docs/Diagrams/tests/open-in-browser-url.txt): Đường link mã hóa nén trực tiếp vào `app.diagrams.net` để xem và chỉnh sửa trực tuyến chỉ với 1 cú click.

---

## 🌐 Mở Trực Tiếp Trên Trình Duyệt (1-Click Web Viewer & Editor)

Bấm vào liên kết sau để mở diagram trực tiếp trên trang biên tập Draw.io (app.diagrams.net):

👉 **[Mở Diagram Trên Diagrams.net](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22xml%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%227V1bd5u6Ev41Wit9aJYQF5tHLibJqZt2J%2B7eu%2BfFC2PF6ISAyyVNzq8%2FSxJgLsLBO46r9rSrq7URFqD5ZjTzaUYA1Xl4ukj9bfgxWeMIILh%2BAqoLEFI0hAD9C9fP%2FMhUh%2FzAJiXr8qTdgVvyX1werE4ryBpnrRPzJIlysm0fDJI4xkHeOuanafK9fdpdErWvuvU3uHfgNvCj%2FtG%2FyDoPy6M6hLuGS0w2YXVppXrAlR%2Fcb9KkiMsLAqR6U8%2FyHPpZnQFoAQTpX9VJkyRvHaoaHp4cHNEBrcaK9%2B2NO7m%2B9xTH%2BT%2F4fU7yCC9XfhzjlHf16EcFrh7HiHKg2iuAYJY%2Fl%2BNlfCvoo9h3SZy%2Fz5g06WWU6fYJqDaTU5Sk%2FCBAKvSUCbJYS%2FVLgIwN%2FX%2F%2BBcwUYNvARNcXAMEFcAxgeexfWB1RwVRxAKLfeWv5E%2BcKIOjSdtNk5%2F5ZtVi05eLK%2BkRPuCqPTo3rMZ2cfbmd3QAE3wMEv9DGq%2BvF7MZyFlef6O%2B9%2Bae%2F3lXDApC3qh6lHqqUDn3nYLb141FDqIqHUJvoumEKh%2FAjvXdbAwiG9JPlxCFA8FvxTJUobRy65%2B3mln5mH116T%2FSXW96E6PecjYwFrEm84de%2F3tAhs2E1ZC6hqs4ua8abcqjmVatN%2B78gfkJPItXYT2I2tFfvytP%2FLhssFyAYsb7op3myIQFA0IkIRTM%2F1606sQP6HI%2FVT3WAIHt6S6EPG4RVw4Rey%2FaDexyvm7LiUqgkg1oCQUyJMVUKBaj295Dk%2BHbrB7T1e%2BpvgWqH%2BUNUNt%2BRKHK4hFyq8uwPlXOeJve40eLYrj5T6pbKurAjob9Ovpdf%2FIhsYqC6AY5znNb394jTHD8NKrrStTJdXb%2FAyQPOUzo8ZS%2BV4SotNdL51%2B8Ns6dOy3PChskzymN%2BaWo3dc%2BDpgYgr7Q2owxR5MdYWYbYXwsMkXJ%2BiO4yDYSWs%2Fh0826PoOHBgoZoqjkTkaDrFqrRImjQ47flXSjVdz4TKuoPRIAC%2BxBQkQAB2okQsErWz4KJ6IhS9KBnitXVtmaG5wrVtScfPw1K%2BcETSksbKa3p9CTiQkMKi84Hp%2BAzNq1yHf3zavYXtfvW19mRVXXiqNbMFQm5bpFeVTUota6iU%2Biq5eliXZ2ZbrNFAl3tiUsyZVWHlFWlyjr%2FdHHlsA4M%2F4EKhf8LELxdWIsZQPDzJXPGXXoxZ341u14cVdSuOZlAQyTqukV6jZ3IPbuqp9BYz7NntkiMnjszppZMGtsTl2Qaqw1prHbeDIws57IR%2FlpaFRhNla9UVS%2BrBoMFRpbzYXbtCjXdtY%2FsL%2BumweLWvr9ctUiv0ooyZhZWf5hOa6fxmF1PE3rMtjdhHUqj0315iZRaJK8TKHWcrPEyy%2F007wnMrogXjxIfwNGAqdRcTNETJ44iss3wMUNY1TAtpa%2BSd%2BzPCyqpdRmNNxOv2pGuIaAwDJE26icRbpHhdOkHOUnifXQqZ6E4rfESv5aHjE3LOdcVjGYfr8MKP%2B6WdVlOAzTwinbUXMEo8%2FQBIOr%2BBREJ7gGCMbsBi2IxK1YPJGfNgqvUvNuU8Yl3JKLajmCYlFe3J4HoIWDQ5AB3vZhHpeZq8A4zNm3LhfoKAO%2BUCfI7gEctg6bAU%2BHf7BB4AuNWTzynJfA4%2FMky8Ld5keKX0c84AkYGrFq2LyuhYCuUqu5wyLNHHOfjGfh53TNTpXgTYoBgEjsc5g77crsDOG0K%2FZiuF4k7XIT13VEQh%2B3bw%2FTuzrcp%2B9%2FFd34R5Wf7fKpjIrpDefwsiNY0uSEdsMWI5aMfkbWfj8A1C6f5Esb7jKwp4P7kP2aTwkjkfqiRpT6wtRwfIJjibwVJ8ZpjlVptn2rMGX7wScQPpniDn94NWeuGX2ED06xmGgsStrTCPtJO%2BCemM6uiPp0ifkO4CefrS9XSDFt%2FKu25umWLOpVenAj9HfrgZ0H%2FRHKDvsYByUgSc%2Fz3wO8OOxUC9A1CRPX6KAmTh1WRHR6rzDxV7OCOR4hJubzZCy4vOhVEph0DqVbfmy6vCCInimcKssRpmqRLEkckHmEgL3emjS05h00zUqHCnJDmSvDZVdk5nNFrjfcAbG6uknZQZYMpRexjfSdKzE4o19JJvC1KhyDcd7NlmsrQ4n%2BHXrGKPHl%2FlwRFtjO2SblO34oAuN1tXijzyVHtqDfzkIeEWuIgA43TElOxFVsSO9r1IlS9ryQ%2F1DGmceEdeXpZO16MB7M6cPK7oDZ1sj%2FSG5u4Qjut7mDqBt0IrbyEBSw77ulsmXZixcxbEGSCjFKWxvVY%2Fkr7qaPq%2BgrhSsk0l4fLJD6VyzFaVaRyOUy5NaX0t6PEXxMq0Jf0hXHhTovqiHfMR77zUylaSkKFzwlsgglrPRutHbeY9kqyeXWLkN0azNMCC3%2FghEV1B2bcNe2Xi8VngOAN%2FlbgjHb82X%2BmD%2F%2Fbbz7Eb9YEPOAPJkJGI%2FhzDVfmYtSIVMkL4D3zMF7THNTx7pBLMn8V4TbDV%2FMvOg01z%2BINtf%2Fc31knBT%2Bds4DvhJ3udehut4Qnl5Y5H7f3OMI5jYThvDlCx%2FJsBjMGxvMjuo0U25AE6V3PRjakr3im5TLFASaPI9x%2FnRrsMj%2BTzdcVUex1bHfcNIsj8f33jmDO21Sdjf2UwtBzkuSeUEgvkns81h0R0jHNxFmactuMJfKU5eAGrYnp7Ma2nFPxgZ3V15%2FFsiv1gp3kgN%2BmSYCz7GXAG%2BfDKc%2FXmwaFvO3mN%2Fdx6Ny689HK0CGr85BOGnaRkZjdd5VvLfolR%2B9jPTHEtf2%2BCF%2BIMZqhrevn%2FsrP8G%2FIHwR5XTLI1yzgqjLbHcyL0S0AVum%2BQBbTBXXYdkQC0HU8ZyZe4R6PDkP3NEMWAlBRzDY8DEMuBrAM2RgL%2BLI5bGc6tLmDW5w%2BMl%2FxzPFzVu9xIN03YGYfGOrU3vXK4Et7eqrtm04%2FHxD13fnRke3bL0fOdYM1YyIX5VCQZZ742WgE7413FrQn%2Bn%2BTlGqw0PMmAMdP5Lu%2BVru%2B2mDOKuUJwoQtdu8nEkWLjrwwjClencBhKXmPcWsEj30fZUOazgHPLako9d9qMj7Sk01NdpFetk3iDC%2BT%2B1eSG6X5RRDW5hdBurT86cOhXDXFo8r0Y8M%2FE1boWIWWOQvR6lthwippNvivW1rbKej6op5MCFtZ54%2FdcNKnSrfMcr0LAyfHhfvx%2FRrZvN7JVC6vt3Rrii3N%2B6Bpm2OyPyYv0tG3vCNRpUWepHg08Pde5AaviyeAvH8XWe5Th92bJ4Ef1ZffR5%2FYKiU3Aj9gyVIBcHRgmXw1NDuZE%2FTLM9ayob0gyxTHa5wusyIYR2xMzxnSYlaiMFD1%2FbGuDB%2Fv7uxFtvvpI0AezRt0Gt7WQFw5kAbVSU4Nwp3VLmepludkM6Q%2FlFfo1Nqf3SRFjo9L6g0n3CuGpWr9IhoB%2BBXD0FVNEvB3XRvpwE%2BX5zHF%2Bigjb45L3N7LbO%2FxTUaqyR8F31aCxwP50HJ7lSJQRcDBHu0Sq0vnQfKaogwYCU526%2F0R15GHVm4N07GOyrWfvlzAt4ITTSHjtUiqKUTyGUREDH4YKed%2FWs%2FSkWSzRZ9CVVDnLXc9y9SUpp4Frzd4qQiMYVd06w2uxjFJ8zDZJLEfzXZH7bYS786ZJ8m2PPgfnOfP5ej7RZ60hX5I9Qa%2FP3pT%2B%2BWEYJYUaYAbAG5UZuV%2BusF5d4bYFfaMlHKKIz%2Bnq6LN676xyFBPZItyoqLbp5RZBLtlUupJyS3RrkluFqpVCqsIFPoVSOiVcfXx0Kp0kRgOah8OKdlsmMvOqmmkEP%2F45AzDRVPXfGPxd8qYetIXFIVIDAFNTiO%2BJ5B%2FheyE9To9AfbrGiSWn74ksbj%2B4kNzYWC4AgcC3b5OgO7KIffR9LxtKo7ivK2uiypcRNa%2BW%2BMgMV4MvqLFZrEeZOyh5aP2MlZV5yVw1f%2FvISOseBF7jGXKv8RgmSzTuteWl9Cr2G4tAcoNirWfhfW1xiIEP5H8b7o9xblefvtablaB4zx9bjTRr1%2BP5GXWRSE%2FccgxHSgPvNw7I33FmSxT0gFLaNpkqk8kmJL6dRISA8Ss7nP5SPD3Hk72Ev6SBKh7vNW91kbTVSgKV17v4rYKDEQuy8%2BBDQUu%2FS1dfPrWtx%2Fd2pgzK3uOg%2F5iy48ABNINtbHT2b6lGFebudO3tRmjMCHI1ZcZGMpyhZd3UdI3GFIAYM%2Bk8QpBCuspBiXZSEKXWZKISjIIcSDKGPrlRdmqFBimIhrJ1TLLUmVayTYc6YUMdb1Aq6yMpQwC3e6m2Uri%2FMkVXIpz7YfcvzpjVWbEaGW4nPNkjZGExK%2BBjNdP6Y2kZJGT18lclhkHenmzQ9TUdTtDYkVai8dttipsBpM1dWUqgnJSyZDzOm6iyUzsyIg34CYEOfEnpbiG%2Bqt6tdLUf278dpuQON%2FrCHXv6jP9xW4pvn4fUZVeAYffpNNTBn43w2PA9KUehqNplEHnYkEa9mIgHY7OwkiemVdS2mX%2FzDuQBi%2Bz4aUcb0bNblDup9SBC8%2BAhzd1hvtvbAxGZZ3ahyHHrJs1LjM8pvw22bxMeuC4we%2FTKsdXEi5OrmyBwToBkbvWz7GWGRnmvpXE%2FfuWSLyaeEASdTOJ8O1WE0WJ92Jnq5mjLDFwEKx8w5hkoZyczx4UvHZNr51J3pOk1CRPhDd0olslI%2Faqc9grYUza56J8Owx7F8XZfHYxu3bfsTcIirLZd8VP8SrbNndcqb9D4EFgesDUgF3uhbHnZZS7FybuMgn7b0v8wswYtILBrXjZKw8vG87zIxlRSvvy40ycA57Y44n6o5%2B4ng4FT0z31%2F6c4gzH%2BfAGxOypxfU7%2FSq1dv3%2Bvt26jz4q8JBRqRfs%2BqNSbyva2gGlPyTNfZuF9XqdSr5jPSc6CO%2BVo9x%2Fzt0uS3RjBRKIiwvL13wethGNO0qLD3pwjW%2B%2BOl7AFcfSf%2FCqKLi%2FrWp%2FE9iYvxg17zayQ0PDNa93xeZFx09D2%2FskLRK8nQLB90MTbGwpZkBP%2Fo7Sbs1LxzlSVU3R9R%2F68krBbtniF5jqxyqBYccbL3OuqJ3dq7HV2f8A%22%7D)

---

## 🏛️ Kiến Trúc 4 Phân Tầng (4-Lane Architecture)

Diagram được cấu trúc dưới dạng **4 Swimlanes** (Làn bơi kiến trúc) trực quan:

| Làn | Tên Phân Tầng | Vai Trò & Nhiệm Vụ |
|:---|:---|:---|
| **1 (Xanh lam)** | **Người dùng (User / Actor)** | Khởi tạo thao tác (nhập biểu mẫu, chọn dữ liệu, click nút submit, sửa lỗi và tiếp nhận kết quả phản hồi). |
| **2 (Tím)** | **Giao diện (UI / View Layer)** | Bắt các sự kiện chuột/phím (`onClick`, `onSubmit`), ngăn chặn hành vi mặc định, hiển thị trạng thái chờ (Spinner/Disable), báo lỗi thị giác (Inline Error/Toast) và re-render giao diện mới. |
| **3 (Vàng cam)** | **Logic & State phía Client** | Thực hiện Client-side Validation (format, required field), quản lý trạng thái tải (`isLoading`), gọi API bất đồng bộ, cập nhật Store (Redux/Zustand) và bắt ngoại lệ mạng. |
| **4 (Xanh lá)** | **Dịch vụ Máy chủ (Backend & DB)** | Tiếp nhận Request, xác thực Auth Token, kiểm tra quyền (RBAC), thực thi Business Logic, truy vấn/lưu Database và trả về HTTP Response (200 OK hoặc mã lỗi 4xx/5xx). |

---

## 🔄 3 Luồng Xử Lý Chính Trong Diagram

### 1. Luồng Thành Công Hoàn Hảo (Happy Path)
1. **Người dùng** nhập thông tin và click nút hành động (ví dụ: Nút Gửi / Đăng nhập / Lưu).
2. **UI** bắt sự kiện qua Event Listener, gọi `event.preventDefault()`.
3. **Client Logic** kiểm tra hợp lệ dữ liệu (Client Validation).
4. Dữ liệu hợp lệ `[Yes]` ➔ Chuyển `isLoading = true`, UI hiển thị Spinner và disable nút bấm (chống double click).
5. Gửi HTTP Request tới **Backend**.
6. **Backend** xác thực Token, thực hiện logic nghiệp vụ và ghi nhận vào Database.
7. Xử lý thành công `[Yes]` ➔ Trả về `HTTP 200 OK` kèm JSON Payload.
8. **Client** cập nhật State Store, tắt loading state.
9. **UI** render dữ liệu mới, hiển thị Toast thông báo thành công.
10. **Người dùng** nhìn thấy kết quả mong muốn và kết thúc chu trình tương tác.

### 2. Luồng Lỗi Kiểm Tra Phía Client (Client-Side Validation Fail)
- Dữ liệu không hợp lệ `[No]` ➔ **UI** tô đỏ viền trường dữ liệu (Inline Error), hiển thị tooltip cảnh báo và tự động focus vào ô bị lỗi.
- **Người dùng** đọc hướng dẫn lỗi, sửa lại giá trị và bấm gửi lại mà không tốn tài nguyên gọi mạng tới máy chủ.

### 3. Luồng Lỗi Máy Chủ (Server Exception / Error Handling)
- Khi Backend xử lý thất bại `[Fail - 4xx/5xx]` (sai mật khẩu, trùng lặp dữ liệu, lỗi database, quá tải mạng) ➔ Phản hồi mã lỗi về Client.
- **Client Logic** bắt ngoại lệ (`catch error`), tắt trạng thái loading.
- **UI** hiển thị thông báo Toast cảnh báo lỗi từ server, kích hoạt lại nút bấm và giữ nguyên nội dung đã nhập để người dùng không phải gõ lại từ đầu.
