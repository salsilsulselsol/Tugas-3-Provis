// File: cookingz-backend/controllers/userController.js

const db = require('../db');

// Fungsi untuk mendapatkan profil pengguna yang sedang login ('me')
exports.getMyProfile = async (req, res) => {
  // Asumsi: ID pengguna didapat dari middleware otentikasi (misal: JWT)
  // Untuk sekarang, kita akan hardcode user ID 1 untuk pengujian.
  // Ganti baris ini dengan `const userId = req.user.id;` setelah otentikasi siap.
  const userId = 1; 

  if (!userId) {
    return res.status(401).json({ message: 'Akses ditolak. Tidak ada pengguna yang terautentikasi.' });
  }

  try {
    // 1. Ambil data dasar pengguna dari tabel 'users'
    const userQuery = 'SELECT id, username, full_name, email, cooking_level, bio, profile_picture FROM users WHERE id = ?';
    const [users] = await db.query(userQuery, [userId]);

    if (users.length === 0) {
      return res.status(404).json({ message: 'Pengguna tidak ditemukan.' });
    }

    const userProfile = users[0];

    // 2. Hitung jumlah resep yang dimiliki pengguna
    const recipesCountQuery = 'SELECT COUNT(*) as recipe_count FROM recipes WHERE user_id = ?';
    const [recipeResult] = await db.query(recipesCountQuery, [userId]);
    userProfile.recipe_count = recipeResult[0].recipe_count;

    // 3. Hitung jumlah pengikut (followers)
    const followersCountQuery = 'SELECT COUNT(*) as followers_count FROM user_followers WHERE following_id = ?';
    const [followersResult] = await db.query(followersCountQuery, [userId]);
    userProfile.followers_count = followersResult[0].followers_count;

    // 4. Hitung jumlah yang diikuti (following)
    const followingCountQuery = 'SELECT COUNT(*) as following_count FROM user_followers WHERE follower_id = ?';
    const [followingResult] = await db.query(followingCountQuery, [userId]);
    userProfile.following_count = followingResult[0].following_count;
    
    // Kirim respons dengan data profil yang sudah digabungkan
    res.status(200).json(userProfile);

  } catch (error) {
    console.error('Error saat mengambil profil:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};

// Fungsi BARU untuk mendapatkan semua resep milik seorang pengguna
exports.getUserRecipes = async (req, res) => {
  try {
    const userId = req.params.id;

    const query = `
      SELECT 
        r.id, 
        r.title AS name, 
        r.description, 
        r.image_url AS image, 
        r.cooking_time AS cookingTime, 
        r.difficulty,
        CAST(r.price AS CHAR) as price,
        r.favorites_count AS likes,
        (SELECT AVG(rating) FROM reviews WHERE recipe_id = r.id) AS rating
      FROM recipes AS r
      WHERE r.user_id = ?
    `;

    const [recipes] = await db.query(query, [userId]);
    
    // Konversi semua tipe data ke tipe yang benar (angka) sebelum mengirim JSON
    const recipesTyped = recipes.map(recipe => ({
      ...recipe,
      id: parseInt(recipe.id, 10),
      cookingTime: recipe.cookingTime ? parseInt(recipe.cookingTime, 10) : null,
      likes: recipe.likes ? parseInt(recipe.likes, 10) : null,
      rating: recipe.rating ? parseFloat(recipe.rating) : null
    }));

    res.status(200).json(recipesTyped);

  } catch (error) {
    console.error('Error saat mengambil resep pengguna:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server saat mengambil resep.' });
  }
};

// Fungsi untuk mendapatkan resep favorit pengguna yang sedang login
exports.getMyFavoriteRecipes = async (req, res) => {
  // Untuk sementara kita hardcode userId = 1, sama seperti di getMyProfile.
  // Ganti dengan `const userId = req.user.id;` setelah otentikasi siap.
  const userId = 1;

  if (!userId) {
    return res.status(401).json({ message: 'Akses ditolak.' });
  }

  try {
    // Query ini menggabungkan tabel resep dengan favorit berdasarkan user_id
    const query = `
      SELECT 
        r.id, 
        r.title AS name, 
        r.description, 
        r.image_url AS image, 
        r.cooking_time AS cookingTime, 
        r.difficulty,
        CAST(r.price AS CHAR) as price,
        r.favorites_count AS likes,
        (SELECT AVG(rating) FROM reviews WHERE recipe_id = r.id) AS rating
      FROM recipes AS r
      INNER JOIN recipe_favorites AS rf ON r.id = rf.recipe_id
      WHERE rf.user_id = ?
    `;

    const [recipes] = await db.query(query, [userId]);
    
    // Proses data agar tipe datanya sesuai dengan yang diharapkan frontend
    const recipesTyped = recipes.map(recipe => ({
      ...recipe,
      id: parseInt(recipe.id, 10),
      cookingTime: recipe.cookingTime ? parseInt(recipe.cookingTime, 10) : null,
      likes: recipe.likes ? parseInt(recipe.likes, 10) : null,
      rating: recipe.rating ? parseFloat(recipe.rating) : null
    }));

    res.status(200).json(recipesTyped);

  } catch (error) {
    console.error('Error saat mengambil resep favorit:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server saat mengambil resep favorit.' });
  }
};

// Fungsi untuk mendapatkan profil pengguna berdasarkan ID
exports.getUserById = async (req, res) => {
  try {
    // Ambil ID dari parameter URL, contoh: /users/2 -> req.params.id akan menjadi '2'
    const userId = req.params.id;

    // Kueri ini sama persis dengan yang ada di getMyProfile
    const userQuery = 'SELECT id, username, full_name, email, cooking_level, bio, profile_picture FROM users WHERE id = ?';
    const [users] = await db.query(userQuery, [userId]);

    if (users.length === 0) {
      return res.status(404).json({ message: 'Pengguna tidak ditemukan.' });
    }

    const userProfile = users[0];

    // Hitung jumlah resep
    const recipesCountQuery = 'SELECT COUNT(*) as recipe_count FROM recipes WHERE user_id = ?';
    const [recipeResult] = await db.query(recipesCountQuery, [userId]);
    userProfile.recipe_count = recipeResult[0].recipe_count;

    // Hitung jumlah pengikut (followers)
    const followersCountQuery = 'SELECT COUNT(*) as followers_count FROM user_followers WHERE following_id = ?';
    const [followersResult] = await db.query(followersCountQuery, [userId]);
    userProfile.followers_count = followersResult[0].followers_count;

    // Hitung jumlah yang diikuti (following)
    const followingCountQuery = 'SELECT COUNT(*) as following_count FROM user_followers WHERE follower_id = ?';
    const [followingResult] = await db.query(followingCountQuery, [userId]);
    userProfile.following_count = followingResult[0].following_count;
    
    // Kirim respons
    res.status(200).json(userProfile);

  } catch (error) {
    console.error(`Error saat mengambil profil untuk ID ${req.params.id}:`, error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};

// Fungsi untuk memperbarui profil pengguna yang sedang login
exports.updateMyProfile = async (req, res) => {
  // Untuk sementara kita hardcode ID pengguna = 1.
  // Ganti dengan `const userId = req.user.id;` setelah otentikasi siap.
  const userId = 1; 

  const { fullName, username, bio } = req.body;

  // Objek untuk menampung field yang akan di-update
  const fieldsToUpdate = {};

  // Hanya tambahkan field ke objek jika nilainya ada (tidak null atau undefined)
  if (fullName !== undefined) fieldsToUpdate.full_name = fullName;
  if (username !== undefined) fieldsToUpdate.username = username;
  if (bio !== undefined) fieldsToUpdate.bio = bio;

  // Cek jika ada file gambar yang di-upload
  if (req.file) {
    fieldsToUpdate.profile_picture = '/uploads/' + req.file.filename;
  }

  // Cek jika tidak ada data sama sekali untuk di-update
  if (Object.keys(fieldsToUpdate).length === 0) {
    return res.status(400).json({ message: 'Tidak ada data untuk diperbarui.' });
  }

  // Membangun query SET secara dinamis
  // Contoh: SET `full_name` = ?, `bio` = ?
  const setClause = Object.keys(fieldsToUpdate)
    .map(key => `${key} = ?`)
    .join(', ');

  // Mengambil nilai-nilai yang akan di-update
  const values = [...Object.values(fieldsToUpdate), userId];
  
  const query = `UPDATE users SET ${setClause} WHERE id = ?`;

  try {
    const [result] = await db.query(query, values);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Pengguna tidak ditemukan, update gagal.' });
    }

    res.status(200).json({ message: 'Profil berhasil diperbarui!' });

  } catch (error) {
    // Tangani kemungkinan error duplikat username
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Username sudah digunakan. Silakan pilih yang lain.' });
    }
    console.error('Error saat update profil:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server saat update profil.' });
  }
};

// Fungsi untuk mengambil daftar FOLLOWING (yang di-follow oleh user :id)
exports.getFollowingList = async (req, res) => {
  try {
    const profileUserId = req.params.id; // ID profil yang sedang dilihat
    const loggedInUserId = 1; // ID pengguna yang login (hardcode untuk testing)

    // Query dimodifikasi untuk menambahkan status 'isFollowedByMe'
    const query = `
      SELECT 
        u.id, u.username, u.full_name, u.profile_picture,
        -- Cek apakah ada relasi follow dari pengguna login ke setiap user (u.id) di daftar ini
        CASE WHEN EXISTS (
          SELECT 1 FROM user_followers 
          WHERE follower_id = ? AND following_id = u.id
        ) THEN 1 ELSE 0 END AS isFollowedByMe
      FROM users u
      JOIN user_followers uf ON u.id = uf.following_id
      WHERE uf.follower_id = ?
    `;
    const [following] = await db.query(query, [loggedInUserId, profileUserId]);
    res.status(200).json(following);
  } catch (error) {
    console.error('Error saat mengambil daftar following:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};

// Fungsi untuk mengambil daftar FOLLOWERS dari user :id
exports.getFollowersList = async (req, res) => {
  try {
    const profileUserId = req.params.id; // ID profil yang sedang dilihat
    const loggedInUserId = 1; // ID pengguna yang login (hardcode)

    // Query dimodifikasi untuk menambahkan status 'isFollowedByMe'
    const query = `
      SELECT 
        u.id, u.username, u.full_name, u.profile_picture,
        -- Cek apakah ada relasi follow dari pengguna login ke setiap user (u.id) di daftar ini
        CASE WHEN EXISTS (
          SELECT 1 FROM user_followers 
          WHERE follower_id = ? AND following_id = u.id
        ) THEN 1 ELSE 0 END AS isFollowedByMe
      FROM users u
      JOIN user_followers uf ON u.id = uf.follower_id
      WHERE uf.following_id = ?
    `;
    const [followers] = await db.query(query, [loggedInUserId, profileUserId]);
    res.status(200).json(followers);
  } catch (error) {
    console.error('Error saat mengambil daftar followers:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};

// Fungsi untuk follow seorang pengguna
exports.followUser = async (req, res) => {
  // Untuk sementara, pengguna yang login di-hardcode ID-nya = 1
  // Nantinya, ini harus didapat dari token otentikasi: const loggedInUserId = req.user.id;
  const loggedInUserId = 1;
  
  // ID pengguna yang akan di-follow, didapat dari parameter URL
  const userToFollowId = req.params.id;

  // Mencegah pengguna mem-follow diri sendiri
  if (loggedInUserId == userToFollowId) {
    return res.status(400).json({ message: 'Anda tidak bisa mengikuti diri sendiri.' });
  }

  try {
    // Query untuk menambahkan relasi follow ke dalam tabel user_followers
    const query = 'INSERT INTO user_followers (follower_id, following_id) VALUES (?, ?)';
    await db.query(query, [loggedInUserId, userToFollowId]);

    res.status(200).json({ message: `Anda sekarang mengikuti pengguna dengan ID ${userToFollowId}` });

  } catch (error) {
    // Tangani jika relasi sudah ada (mencegah duplikat)
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Anda sudah mengikuti pengguna ini.' });
    }
    console.error('Error saat follow user:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};

// Fungsi untuk unfollow seorang pengguna
exports.unfollowUser = async (req, res) => {
  // Hardcode ID pengguna yang login
  const loggedInUserId = 1; 
  
  // ID pengguna yang akan di-unfollow
  const userToUnfollowId = req.params.id;

  try {
    // Query untuk menghapus relasi follow dari tabel
    const query = 'DELETE FROM user_followers WHERE follower_id = ? AND following_id = ?';
    const [result] = await db.query(query, [loggedInUserId, userToUnfollowId]);

    // Cek apakah ada baris yang terhapus
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Anda tidak sedang mengikuti pengguna ini, tidak ada yang di-unfollow.' });
    }

    res.status(200).json({ message: `Anda berhenti mengikuti pengguna dengan ID ${userToUnfollowId}` });

  } catch (error) {
    console.error('Error saat unfollow user:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
};