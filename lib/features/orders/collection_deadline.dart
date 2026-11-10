/// The agreed MVP collection window, anchored to recorded locker arrival.
/// Never pass the time the app opened as [arrivedAt]. The backend must persist
/// this deadline; grouped parcels may have a different deadline from InPost.
DateTime collectionDeadlineFromArrival(DateTime arrivedAt) => arrivedAt.toUtc().add(const Duration(hours: 72));
