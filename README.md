# Matrix Calculator - Kelompok 9

**Mata Kuliah:** Perancangan Sistem Digital  
**Departemen:** Teknik Elektro, Universitas Indonesia

---

## 📝 Deskripsi Proyek
Proyek **Matrix Calculator** ini adalah unit akselerator perangkat keras (*hardware accelerator*) berbasis FPGA yang dirancang menggunakan bahasa VHDL untuk melakukan komputasi aljabar linear secara efisien. Sistem ini mampu memproses operasi matriks dengan dimensi maksimal $5\times5$ menggunakan representasi data *8-bit signed integer*. Fungsionalitas alat mencakup operasi aritmatika dasar (penjumlahan, pengurangan), perkalian matriks, transpose, hingga perhitungan determinan dan invers. Arsitektur sistem memisahkan jalur kendali (*Control Path*) berbasis FSM dan jalur data (*Datapath*) untuk memastikan modularitas, serta dilengkapi mekanisme *Error Handling* untuk mencegah kesalahan dimensi input dan saturasi data.

---

## 👥 Anggota Kelompok dan Pembagian Tugas

Berikut adalah pembagian peran dan tanggung jawab anggota Kelompok 9 dalam pengembangan proyek ini:

| Nama Anggota | NPM | Peran (*Role*) | Tanggung Jawab Utama |
| :--- | :--- | :--- | :--- |
| **Muhammad Daffa Rizki** | 2406402050 | *Control Unit & Integration* | • Merancang FSM sebagai otak sistem untuk menerjemahkan Opcode menjadi sinyal kontrol.<br>• Menangani logika *Error Handling*.<br>• Mengintegrasikan seluruh modul (ALU, Multiplier, Control) di level teratas (*Top Level*). |
| **Akbar Anvasa Faraby** | 2406405361 | *Multiplier & Datapath* | • Merancang unit *Datapath* khusus untuk operasi perkalian matriks.<br>• Mengelola manajemen aliran data dan perancangan elemen pemroses (*Processing Element*). |
| **Zhafarrel Alvarezqi P. K.** | 2406404945 | *ALU Common & Arithmetic* | • Merancang unit aritmatika untuk operasi Penjumlahan, Pengurangan, dan Transpose.<br>• Mengembangkan algoritma logika untuk perhitungan Determinan dan Invers Matriks. |
| **Yusri Sukur** | 2406345305 | *Verification & Testbench* | • Menyusun skenario pengujian (*Testbench*) dan menangani pembacaan/penulisan file I/O (.txt).<br>• Memvalidasi kebenaran hasil simulasi dibandingkan perhitungan manual. |

---

## 🔗 Tautan Dokumen
Berikut adalah akses ke dokumen lengkap proyek akhir ini:

* 📄 **Laporan Proyek Akhir:** [Klik di sini untuk melihat Laporan](https://docs.google.com/document/d/1W9oFw5opDDZ_TSQLNEBQ64WVdsEJw1VvqlEr2EIaDOU/edit?usp=sharing)
* 📊 **Slide Presentasi (PPT):** [Klik di sini untuk melihat PPT](https://docs.google.com/presentation/d/1VO49OSZueXe3FMjiOuPkLu2EWlT0kll-JoKJ6cDTpss/edit?usp=sharing)
