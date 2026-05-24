// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingTransactionModelCollection on Isar {
  IsarCollection<PendingTransactionModel> get pendingTransactionModels =>
      this.collection();
}

const PendingTransactionModelSchema = CollectionSchema(
  name: r'PendingTransactionModel',
  id: -8283665788138400767,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.double),
    r'merchantName': PropertySchema(
      id: 1,
      name: r'merchantName',
      type: IsarType.string,
    ),
    r'notificationId': PropertySchema(
      id: 2,
      name: r'notificationId',
      type: IsarType.long,
    ),
    r'rawBody': PropertySchema(id: 3, name: r'rawBody', type: IsarType.string),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _pendingTransactionModelEstimateSize,
  serialize: _pendingTransactionModelSerialize,
  deserialize: _pendingTransactionModelDeserialize,
  deserializeProp: _pendingTransactionModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _pendingTransactionModelGetId,
  getLinks: _pendingTransactionModelGetLinks,
  attach: _pendingTransactionModelAttach,
  version: '3.3.2',
);

int _pendingTransactionModelEstimateSize(
  PendingTransactionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.merchantName.length * 3;
  bytesCount += 3 + object.rawBody.length * 3;
  return bytesCount;
}

void _pendingTransactionModelSerialize(
  PendingTransactionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeString(offsets[1], object.merchantName);
  writer.writeLong(offsets[2], object.notificationId);
  writer.writeString(offsets[3], object.rawBody);
  writer.writeDateTime(offsets[4], object.timestamp);
}

PendingTransactionModel _pendingTransactionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingTransactionModel();
  object.amount = reader.readDouble(offsets[0]);
  object.id = id;
  object.merchantName = reader.readString(offsets[1]);
  object.notificationId = reader.readLong(offsets[2]);
  object.rawBody = reader.readString(offsets[3]);
  object.timestamp = reader.readDateTime(offsets[4]);
  return object;
}

P _pendingTransactionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingTransactionModelGetId(PendingTransactionModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingTransactionModelGetLinks(
  PendingTransactionModel object,
) {
  return [];
}

void _pendingTransactionModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  PendingTransactionModel object,
) {
  object.id = id;
}

extension PendingTransactionModelQueryWhereSort
    on QueryBuilder<PendingTransactionModel, PendingTransactionModel, QWhere> {
  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingTransactionModelQueryWhere
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QWhereClause
        > {
  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterWhereClause
  >
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PendingTransactionModelQueryFilter
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QFilterCondition
        > {
  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  amountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'merchantName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'merchantName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'merchantName', value: ''),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  merchantNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'merchantName', value: ''),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  notificationIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notificationId', value: value),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  notificationIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notificationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  notificationIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notificationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  notificationIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notificationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawBody',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawBody',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawBody',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawBody', value: ''),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  rawBodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawBody', value: ''),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PendingTransactionModel,
    PendingTransactionModel,
    QAfterFilterCondition
  >
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PendingTransactionModelQueryObject
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QFilterCondition
        > {}

extension PendingTransactionModelQueryLinks
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QFilterCondition
        > {}

extension PendingTransactionModelQuerySortBy
    on QueryBuilder<PendingTransactionModel, PendingTransactionModel, QSortBy> {
  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByMerchantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByMerchantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByNotificationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationId', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByNotificationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationId', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByRawBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawBody', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByRawBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawBody', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension PendingTransactionModelQuerySortThenBy
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QSortThenBy
        > {
  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByMerchantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByMerchantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByNotificationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationId', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByNotificationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationId', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByRawBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawBody', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByRawBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawBody', Sort.desc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension PendingTransactionModelQueryWhereDistinct
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QDistinct
        > {
  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QDistinct>
  distinctByMerchantName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'merchantName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QDistinct>
  distinctByNotificationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationId');
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QDistinct>
  distinctByRawBody({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawBody', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransactionModel, PendingTransactionModel, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension PendingTransactionModelQueryProperty
    on
        QueryBuilder<
          PendingTransactionModel,
          PendingTransactionModel,
          QQueryProperty
        > {
  QueryBuilder<PendingTransactionModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingTransactionModel, double, QQueryOperations>
  amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<PendingTransactionModel, String, QQueryOperations>
  merchantNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'merchantName');
    });
  }

  QueryBuilder<PendingTransactionModel, int, QQueryOperations>
  notificationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationId');
    });
  }

  QueryBuilder<PendingTransactionModel, String, QQueryOperations>
  rawBodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawBody');
    });
  }

  QueryBuilder<PendingTransactionModel, DateTime, QQueryOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
