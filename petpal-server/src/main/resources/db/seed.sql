INSERT INTO user (id, phone, password, nickname, avatar_url, bio) VALUES
(1, '13800000001', '123456', 'Xiaoman', 'https://placehold.co/96x96', 'Cat and dog care journal'),
(2, '13800000002', '123456', 'Aning', 'https://placehold.co/96x96', 'Weekly grooming notes');

INSERT INTO user_follow (follower_id, following_id) VALUES
(1, 2),
(2, 1);

INSERT INTO pet (id, owner_id, name, species, breed, gender, birthday, weight, avatar_url, is_neutered) VALUES
(1, 1, 'Nuomi', 'CAT', 'British Shorthair', 'FEMALE', '2022-05-01', 4.30, 'https://placehold.co/120x120', 1),
(2, 1, 'Qiqi', 'DOG', 'Corgi', 'MALE', '2021-11-18', 10.80, 'https://placehold.co/120x120', 0);

INSERT INTO pet_health_record (pet_id, record_type, title, description, record_date, next_date) VALUES
(1, 'CHECKUP', 'Annual checkup', 'Bloodwork normal and appetite stable.', '2026-02-18', '2027-02-18'),
(1, 'MEDICATION', 'Deworming', 'Completed routine deworming.', '2026-03-01', '2026-06-01');

INSERT INTO pet_vaccine (pet_id, vaccine_name, vaccinated_at, next_due_at, hospital) VALUES
(1, 'Feline triple vaccine', '2025-04-18', '2026-04-11', 'Cloud Vet Center'),
(2, 'Rabies', '2025-07-01', '2026-06-24', 'Cloud Vet Center');

INSERT INTO service_provider (id, name, type, address, phone, rating, cover_url, business_hours) VALUES
(1, 'Cloud Vet Center', 'HOSPITAL', '188 Dingxiang Rd, Pudong', '021-12345678', 4.8, 'https://placehold.co/800x400', '09:00-20:00'),
(2, 'Bubble Grooming', 'GROOMING', '28 Yanping Rd, Jingan', '021-87654321', 4.7, 'https://placehold.co/800x400?text=grooming', '10:00-21:00'),
(3, 'Forest Boarding', 'BOARDING', '111 Lianhua Rd, Xuhui', '021-99887766', 4.6, 'https://placehold.co/800x400?text=boarding', '08:00-22:00');

INSERT INTO service_item (id, provider_id, name, price, duration) VALUES
(1, 1, 'Routine Checkup', 59.00, 30),
(2, 1, 'Vaccination', 88.00, 20),
(3, 2, 'Basic Bath', 79.00, 60),
(4, 2, 'Full Grooming', 199.00, 120),
(5, 3, 'Day Boarding', 128.00, 480),
(6, 3, 'Weekend Boarding', 299.00, 2880);

INSERT INTO appointment (id, order_no, user_id, pet_id, provider_id, service_id, status, appointment_time, remark) VALUES
(1, 'PP202603260001', 1, 1, 1, 2, 'CONFIRMED', '2026-12-29 10:30:00', 'Arrive 10 minutes early');

INSERT INTO post (id, user_id, pet_id, content, like_count, comment_count, visibility, status, created_at, updated_at) VALUES
(1, 1, 1, 'Nuomi finished the vaccine today and is already back to sunbathing. #catlife #vaccine', 23, 2, 'PUBLIC', 'ACTIVE', '2026-03-24 18:20:00', '2026-03-24 18:20:00'),
(2, 2, 2, 'Qiqi got a full grooming session and came out looking much more energetic. #doglife #grooming', 56, 1, 'PUBLIC', 'ACTIVE', '2026-03-23 13:10:00', '2026-03-23 13:10:00');

INSERT INTO comment (id, post_id, parent_id, user_id, content, created_at) VALUES
(1, 1, NULL, 2, 'Looks great, and the energy is stable again.', '2026-03-24 19:10:00'),
(2, 1, 1, 1, 'Yes, the vet also said everything is stable.', '2026-03-24 19:18:00'),
(3, 2, NULL, 1, 'The grooming team did a careful job.', '2026-03-23 13:40:00');
