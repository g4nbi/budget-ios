# BUDGET

Aplikasi iOS native untuk merencanakan anggaran pribadi. Data keuangan disimpan secara lokal dengan SwiftData. Tidak ada akun, backend, pelacakan, atau iklan.

Gemini AI bersifat opsional. Kunci API dimasukkan oleh pengguna dan disimpan di Keychain.

## Yang tidak ada di aplikasi ini

- Angka keuangan contoh
- Saldo, gaji, tagihan, atau tujuan rekaan
- Grafik kosong yang berpura-pura berisi data
- Kunci API yang tertanam di kode

Saat pertama dibuka, aplikasi kosong kecuali kategori bawaan non-keuangan seperti Makan, Transportasi, dan Tagihan.

## Syarat

- macOS dengan Xcode 16 atau lebih baru
- iOS 18+
- Swift 6

Lingkungan Linux tempat proyek ini dirakit **tidak dapat** menjalankan `xcodebuild`. Buka proyek di Mac untuk membangun, menguji, dan menginstal.

## Membuka proyek

```bash
git clone <url-repositori-ini>
cd budget-ios
open BUDGET.xcodeproj
```

Pilih skema `BUDGET`, simulator iPhone, lalu Run.

Bundle identifier: `app.budget.local`

Code signing dinonaktifkan di pengaturan proyek agar CI bisa membangun tanpa sertifikat. Untuk memasang ke perangkat fisik, aktifkan signing dengan tim Apple milikmu di Xcode.

## Menjalankan tes

Di Xcode: Product → Test.

Atau:

```bash
xcodebuild \
  -project BUDGET.xcodeproj \
  -scheme BUDGET \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Tes mencakup:

- perhitungan saldo rekening
- transfer, refund, penyesuaian
- pengecualian tabungan
- progres anggaran
- siklus bulan keuangan, termasuk Februari kabisat dan tanggal 31
- sisa hari, termasuk nol
- rumus estimasi “Aman dibelanjakan”
- format Rupiah
- ekspor CSV/JSON

## GitHub Actions

Alur `.github/workflows/build.yml` berjalan di `macos-15` dan:

1. memilih Xcode 16.x
2. membangun proyek
3. menjalankan XCTest di simulator
4. membangun untuk `generic/platform=iOS` tanpa code signing
5. mengemas `BUDGET.app` menjadi IPA tidak tertandatangani
6. mengunggah artefak `BUDGET-unsigned.ipa`

Unduh artefak dari tab Actions setelah workflow selesai.

## Menandatangani dan memasang IPA

IPA dari CI **tidak tertandatangani**. Kamu harus menandatanganinya sendiri.

Pilihan yang umum:

1. Buka proyek di Xcode, pilih tim signing, lalu Product → Archive.
2. Tandatangani IPA CI dengan alat seperti `fastlane sigh` / `codesign` dan profil milikmu.
3. Pasang lewat [AltStore](https://altstore.io), Sideloadly, atau metode sideload lain yang kamu pakai.

Aplikasi ini tidak menyertakan sertifikat, profil, atau kunci privat.

## Privasi

- SwiftData lokal
- Tidak ada login
- Tidak ada SDK analitik
- Gemini hanya dipanggil setelah konfirmasi pengguna
- “Hapus semua data” meminta ketikan `HAPUS`
- Kunci Gemini tidak ikut terhapus kecuali opsi itu diaktifkan

## Estimasi “Aman dibelanjakan”

Ini perkiraan, bukan saran keuangan.

```
uang di luar rekening tabungan
+ pemasukan yang masih diharapkan
− pengeluaran wajib yang belum dibayar
− sisa target tabungan
− uang yang disisihkan
= dana fleksibel

dana fleksibel / sisa hari pada bulan keuangan
= estimasi harian
```

Jika data yang dibutuhkan belum ada, aplikasi menjelaskan apa yang kurang. Ia tidak mengisi angka.

## Struktur

```
budget-ios/
├── BUDGET.xcodeproj/
├── BUDGET/
│   ├── App/
│   ├── Models/
│   ├── Services/
│   ├── Store/
│   ├── Features/
│   ├── Components/
│   └── Utilities/
├── BUDGETTests/
├── .github/workflows/build.yml
├── README.md
└── .gitignore
```

Perhitungan uang dipisah dari SwiftUI di `MoneyCalculator` dan `FinanceMonth` agar bisa diuji tanpa antarmuka.
