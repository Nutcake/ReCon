import 'package:intl/intl.dart';

enum SearchSortDirection {
  ascending,
  descending;

  @override
  String toString() => toBeginningOfSentenceCase(name);
}

enum SearchSortParameter {
  creationDate,
  lastUpdateDate,
  firstPublishTime,
  totalVisits,
  name,
  random;

  @override
  String toString() => const {
        SearchSortParameter.creationDate: "Created",
        SearchSortParameter.lastUpdateDate: "Last Updated",
        SearchSortParameter.firstPublishTime: "First Published",
        SearchSortParameter.totalVisits: "Total Visits",
        SearchSortParameter.name: "Name",
        SearchSortParameter.random: "Random",
      }[this]!;

  String serialize() => toBeginningOfSentenceCase(this.name);
}
