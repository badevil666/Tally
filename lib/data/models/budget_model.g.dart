// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBudgetModelCollection on Isar {
  IsarCollection<BudgetModel> get budgetModels => this.collection();
}

const BudgetModelSchema = CollectionSchema(
  name: r'BudgetModel',
  id: 7247118153370490723,
  properties: {
    r'country': PropertySchema(id: 0, name: r'country', type: IsarType.string),
    r'currencySymbol': PropertySchema(
      id: 1,
      name: r'currencySymbol',
      type: IsarType.string,
    ),
    r'savingsGoal': PropertySchema(
      id: 2,
      name: r'savingsGoal',
      type: IsarType.double,
    ),
    r'totalIncome': PropertySchema(
      id: 3,
      name: r'totalIncome',
      type: IsarType.double,
    ),
  },

  estimateSize: _budgetModelEstimateSize,
  serialize: _budgetModelSerialize,
  deserialize: _budgetModelDeserialize,
  deserializeProp: _budgetModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _budgetModelGetId,
  getLinks: _budgetModelGetLinks,
  attach: _budgetModelAttach,
  version: '3.3.2',
);

int _budgetModelEstimateSize(
  BudgetModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.country.length * 3;
  bytesCount += 3 + object.currencySymbol.length * 3;
  return bytesCount;
}

void _budgetModelSerialize(
  BudgetModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.country);
  writer.writeString(offsets[1], object.currencySymbol);
  writer.writeDouble(offsets[2], object.savingsGoal);
  writer.writeDouble(offsets[3], object.totalIncome);
}

BudgetModel _budgetModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BudgetModel();
  object.country = reader.readString(offsets[0]);
  object.currencySymbol = reader.readString(offsets[1]);
  object.id = id;
  object.savingsGoal = reader.readDouble(offsets[2]);
  object.totalIncome = reader.readDouble(offsets[3]);
  return object;
}

P _budgetModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _budgetModelGetId(BudgetModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _budgetModelGetLinks(BudgetModel object) {
  return [];
}

void _budgetModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  BudgetModel object,
) {
  object.id = id;
}

extension BudgetModelQueryWhereSort
    on QueryBuilder<BudgetModel, BudgetModel, QWhere> {
  QueryBuilder<BudgetModel, BudgetModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BudgetModelQueryWhere
    on QueryBuilder<BudgetModel, BudgetModel, QWhereClause> {
  QueryBuilder<BudgetModel, BudgetModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<BudgetModel, BudgetModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterWhereClause> idBetween(
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

extension BudgetModelQueryFilter
    on QueryBuilder<BudgetModel, BudgetModel, QFilterCondition> {
  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  countryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'country',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  countryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'country',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> countryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'country',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  countryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'country', value: ''),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  countryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'country', value: ''),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currencySymbol',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'currencySymbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'currencySymbol',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currencySymbol', value: ''),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  currencySymbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'currencySymbol', value: ''),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  savingsGoalEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'savingsGoal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  savingsGoalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'savingsGoal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  savingsGoalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'savingsGoal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  savingsGoalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'savingsGoal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  totalIncomeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalIncome',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  totalIncomeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalIncome',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  totalIncomeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalIncome',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterFilterCondition>
  totalIncomeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalIncome',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension BudgetModelQueryObject
    on QueryBuilder<BudgetModel, BudgetModel, QFilterCondition> {}

extension BudgetModelQueryLinks
    on QueryBuilder<BudgetModel, BudgetModel, QFilterCondition> {}

extension BudgetModelQuerySortBy
    on QueryBuilder<BudgetModel, BudgetModel, QSortBy> {
  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortByCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'country', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortByCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'country', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortByCurrencySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy>
  sortByCurrencySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortBySavingsGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsGoal', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortBySavingsGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsGoal', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortByTotalIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> sortByTotalIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncome', Sort.desc);
    });
  }
}

extension BudgetModelQuerySortThenBy
    on QueryBuilder<BudgetModel, BudgetModel, QSortThenBy> {
  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'country', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'country', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByCurrencySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy>
  thenByCurrencySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenBySavingsGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsGoal', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenBySavingsGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsGoal', Sort.desc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByTotalIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QAfterSortBy> thenByTotalIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncome', Sort.desc);
    });
  }
}

extension BudgetModelQueryWhereDistinct
    on QueryBuilder<BudgetModel, BudgetModel, QDistinct> {
  QueryBuilder<BudgetModel, BudgetModel, QDistinct> distinctByCountry({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'country', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QDistinct> distinctByCurrencySymbol({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'currencySymbol',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QDistinct> distinctBySavingsGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savingsGoal');
    });
  }

  QueryBuilder<BudgetModel, BudgetModel, QDistinct> distinctByTotalIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalIncome');
    });
  }
}

extension BudgetModelQueryProperty
    on QueryBuilder<BudgetModel, BudgetModel, QQueryProperty> {
  QueryBuilder<BudgetModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BudgetModel, String, QQueryOperations> countryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'country');
    });
  }

  QueryBuilder<BudgetModel, String, QQueryOperations> currencySymbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencySymbol');
    });
  }

  QueryBuilder<BudgetModel, double, QQueryOperations> savingsGoalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savingsGoal');
    });
  }

  QueryBuilder<BudgetModel, double, QQueryOperations> totalIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalIncome');
    });
  }
}
