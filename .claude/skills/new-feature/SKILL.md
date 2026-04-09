---
name: new-feature
description: >
  Flutter Clean Architecture 3-레이어 feature 모듈을 자동 생성합니다.
  feature 이름을 받아 lib/features/{name}/ 아래 전체 폴더 구조와 보일러플레이트 파일을
  한 번에 만들고, Provider DI 체인 등록, UseCase 테스트 파일 생성, build_runner 실행까지
  완료합니다.

  다음 중 하나라도 해당하면 반드시 이 스킬을 사용하세요:
  - "새 기능 추가", "feature 만들어줘", "모듈 생성해줘" 라고 말할 때
  - "/new-feature <이름>" 형식으로 요청할 때
  - 새로운 Clean Architecture 기능 모듈 스캐폴딩이 필요할 때
  - 특정 feature의 entity/repository/usecase/viewmodel을 처음부터 만들어야 할 때
---

# new-feature 스킬

## 목적

사용자가 feature 이름 하나만 주면, Clean Architecture 3-레이어(presentation / domain / data)
파일 전체를 프로젝트 컨벤션에 맞게 생성합니다. 손으로 반복 작성하던 보일러플레이트를 없애는 것이 목표입니다.

---

## 실행 순서

1. **feature 이름 파악** — 입력에서 snake_case 이름을 추출 (예: `card`, `auth_token`)
2. **네이밍 파생** — PascalCase(`Card`, `AuthToken`) 및 단수/복수 결정
3. **디렉토리·파일 생성** — 아래 템플릿대로 순서대로 Write
4. **build_runner 실행** — `dart run build_runner build --delete-conflicting-outputs`
5. **분석 실행** — `flutter analyze`

> 파일 생성은 반드시 **domain → data → presentation → test** 순서를 지킵니다.

---

## 이름 변환 규칙

| 입력 | snake_case (파일명 접두사) | PascalCase (클래스 접두사) |
|------|--------------------------|--------------------------|
| `card` | `card` | `Card` |
| `auth_token` | `auth_token` | `AuthToken` |
| `todo_item` | `todo_item` | `TodoItem` |

패키지명은 `pubspec.yaml`의 `name` 필드에서 읽습니다 (현재 프로젝트: `flutter_harness_engineering_study`).

---

## 생성할 파일 목록

```
lib/features/{name}/
├── domain/
│   ├── entities/{name}_entity.dart
│   ├── repositories/{name}_repository.dart
│   └── usecases/get_{name}s_usecase.dart
├── data/
│   ├── models/{name}_model.dart
│   ├── mappers/{name}_mapper.dart
│   ├── datasources/{name}_data_source.dart
│   ├── repositories/{name}_repository_impl.dart
│   └── {name}_providers.dart          ← DI 체인 (DataSource → Repository → UseCase)
└── presentation/
    ├── view_models/{name}_list_view_model.dart   ← State도 같은 파일에 포함
    ├── screens/{name}_list_screen.dart
    └── widgets/                                   ← 빈 폴더 (이후 위젯 추가용)

test/features/{name}/domain/usecases/get_{name}s_usecase_test.dart
```

---

## 파일 템플릿

아래에서 `{name}` = snake_case, `{Name}` = PascalCase 를 실제 값으로 치환합니다.

---

### 1. `domain/entities/{name}_entity.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{name}_entity.freezed.dart';

@freezed
class {Name}Entity with _${Name}Entity {
  const factory {Name}Entity({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    required bool isCompleted,
  }) = _{Name}Entity;
}
```

**규칙 준수 포인트:**
- `fromJson`/`toJson` 없음 (JSON 직렬화는 data 레이어 Model 담당)
- `package:flutter` import 없음

---

### 2. `domain/repositories/{name}_repository.dart`

```dart
import 'package:flutter_harness_engineering_study/core/error/result.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';

abstract class {Name}Repository {
  Future<Result<List<{Name}Entity>>> get{Name}s();
  Future<Result<{Name}Entity>> get{Name}ById(String id);
  Future<Result<void>> create{Name}({Name}Entity entity);
  Future<Result<void>> update{Name}({Name}Entity entity);
  Future<Result<void>> delete{Name}(String id);
}
```

---

### 3. `domain/usecases/get_{name}s_usecase.dart`

```dart
import 'package:flutter_harness_engineering_study/core/error/result.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/repositories/{name}_repository.dart';

class Get{Name}sUseCase {
  final {Name}Repository _repository;

  Get{Name}sUseCase(this._repository);

  Future<Result<List<{Name}Entity>>> call() {
    return _repository.get{Name}s();
  }
}
```

---

### 4. `data/models/{name}_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{name}_model.freezed.dart';
part '{name}_model.g.dart';

@freezed
class {Name}Model with _${Name}Model {
  const factory {Name}Model({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'is_completed') required bool isCompleted,
  }) = _{Name}Model;

  factory {Name}Model.fromJson(Map<String, dynamic> json) =>
      _${Name}ModelFromJson(json);
}
```

---

### 5. `data/mappers/{name}_mapper.dart`

```dart
import 'package:flutter_harness_engineering_study/features/{name}/data/models/{name}_model.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';

class {Name}Mapper {
  static {Name}Entity toEntity({Name}Model model) {
    return {Name}Entity(
      id: model.id,
      title: model.title,
      description: model.description,
      createdAt: DateTime.parse(model.createdAt),
      isCompleted: model.isCompleted,
    );
  }

  static {Name}Model toModel({Name}Entity entity) {
    return {Name}Model(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt.toIso8601String(),
      isCompleted: entity.isCompleted,
    );
  }
}
```

---

### 6. `data/datasources/{name}_data_source.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/models/{name}_model.dart';

class {Name}DataSource {
  final Dio _client;

  {Name}DataSource(this._client);

  Future<List<{Name}Model>> fetch{Name}s() async {
    final response = await _client.get('/{name}s');
    final list = response.data['data'] as List;
    return list.map((json) => {Name}Model.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<{Name}Model> fetch{Name}ById(String id) async {
    final response = await _client.get('/{name}s/$id');
    return {Name}Model.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> create{Name}({Name}Model model) async {
    await _client.post('/{name}s', data: model.toJson());
  }

  Future<void> update{Name}(String id, {Name}Model model) async {
    await _client.put('/{name}s/$id', data: model.toJson());
  }

  Future<void> delete{Name}(String id) async {
    await _client.delete('/{name}s/$id');
  }
}
```

---

### 7. `data/repositories/{name}_repository_impl.dart`

```dart
import 'package:flutter_harness_engineering_study/core/error/app_failure.dart';
import 'package:flutter_harness_engineering_study/core/error/result.dart';
import 'package:flutter_harness_engineering_study/core/utils/logger.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/datasources/{name}_data_source.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/mappers/{name}_mapper.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/repositories/{name}_repository.dart';

class {Name}RepositoryImpl implements {Name}Repository {
  final {Name}DataSource _dataSource;

  {Name}RepositoryImpl(this._dataSource);

  @override
  Future<Result<List<{Name}Entity>>> get{Name}s() async {
    try {
      final models = await _dataSource.fetch{Name}s();
      final entities = models.map({Name}Mapper.toEntity).toList();
      return Success(entities);
    } catch (e) {
      AppLogger.error('{name} 목록 조회 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }

  @override
  Future<Result<{Name}Entity>> get{Name}ById(String id) async {
    try {
      final model = await _dataSource.fetch{Name}ById(id);
      return Success({Name}Mapper.toEntity(model));
    } catch (e) {
      AppLogger.error('{name} 단건 조회 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }

  @override
  Future<Result<void>> create{Name}({Name}Entity entity) async {
    try {
      final model = {Name}Mapper.toModel(entity);
      await _dataSource.create{Name}(model);
      return const Success(null);
    } catch (e) {
      AppLogger.error('{name} 생성 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }

  @override
  Future<Result<void>> update{Name}({Name}Entity entity) async {
    try {
      final model = {Name}Mapper.toModel(entity);
      await _dataSource.update{Name}(entity.id, model);
      return const Success(null);
    } catch (e) {
      AppLogger.error('{name} 수정 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete{Name}(String id) async {
    try {
      await _dataSource.delete{Name}(id);
      return const Success(null);
    } catch (e) {
      AppLogger.error('{name} 삭제 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }
}
```

---

### 8. `data/{name}_providers.dart`

DataSource → Repository → UseCase 순서의 DI 체인입니다.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_harness_engineering_study/core/network/api_client.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/datasources/{name}_data_source.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/repositories/{name}_repository_impl.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/repositories/{name}_repository.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/usecases/get_{name}s_usecase.dart';

part '{name}_providers.g.dart';

@riverpod
{Name}DataSource {name}DataSource(Ref ref) {
  return {Name}DataSource(ref.watch(dioProvider));
}

@riverpod
{Name}Repository {name}Repository(Ref ref) {
  return {Name}RepositoryImpl(ref.watch({name}DataSourceProvider));
}

@riverpod
Get{Name}sUseCase get{Name}sUseCase(Ref ref) {
  return Get{Name}sUseCase(ref.watch({name}RepositoryProvider));
}
```

> `dioProvider`는 `lib/core/network/api_client.dart`에 정의된 Dio 싱글턴 Provider입니다.

---

### 9. `presentation/view_models/{name}_list_view_model.dart`

State와 ViewModel을 같은 파일에 둡니다.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_harness_engineering_study/core/error/app_failure.dart';
import 'package:flutter_harness_engineering_study/core/error/result.dart';
import 'package:flutter_harness_engineering_study/features/{name}/data/{name}_providers.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';

part '{name}_list_view_model.freezed.dart';
part '{name}_list_view_model.g.dart';

@freezed
class {Name}ListState with _${Name}ListState {
  const factory {Name}ListState({
    @Default([]) List<{Name}Entity> {name}s,
  }) = _{Name}ListState;

  const factory {Name}ListState.error(AppFailure failure) = _{Name}ListStateError;
}

@riverpod
class {Name}ListViewModel extends _${Name}ListViewModel {
  @override
  FutureOr<{Name}ListState> build() async {
    final get{Name}s = ref.watch(get{Name}sUseCaseProvider);
    final result = await get{Name}s();

    return switch (result) {
      Success(:final data) => {Name}ListState({name}s: data),
      Failure(:final failure) => {Name}ListState.error(failure),
    };
  }

  Future<void> delete{Name}(String id) async {
    state = const AsyncValue.loading();
    // TODO: delete{Name}UseCaseProvider 연결 후 구현
    ref.invalidateSelf();
  }
}
```

---

### 10. `presentation/screens/{name}_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_harness_engineering_study/features/{name}/presentation/view_models/{name}_list_view_model.dart';
import 'package:flutter_harness_engineering_study/shared/widgets/error_view.dart';
import 'package:flutter_harness_engineering_study/shared/widgets/loading_view.dart';

class {Name}ListScreen extends ConsumerWidget {
  const {Name}ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({name}ListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('{Name}')),
      body: state.when(
        data: ({name}State) => switch ({name}State) {
          {Name}ListState(:{name}s: final items) => items.isEmpty
              ? const Center(child: Text('항목이 없습니다'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(items[index].title),
                    subtitle: Text(items[index].description),
                  ),
                ),
          {Name}ListStateError(:final failure) => ErrorView(error: failure),
        },
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
      ),
    );
  }
}
```

---

### 11. `test/features/{name}/domain/usecases/get_{name}s_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_harness_engineering_study/core/error/app_failure.dart';
import 'package:flutter_harness_engineering_study/core/error/result.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/entities/{name}_entity.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/repositories/{name}_repository.dart';
import 'package:flutter_harness_engineering_study/features/{name}/domain/usecases/get_{name}s_usecase.dart';

class Mock{Name}Repository extends Mock implements {Name}Repository {}

void main() {
  late Get{Name}sUseCase useCase;
  late Mock{Name}Repository mockRepository;

  setUp(() {
    mockRepository = Mock{Name}Repository();
    useCase = Get{Name}sUseCase(mockRepository);
  });

  final sample{Name} = {Name}Entity(
    id: '1',
    title: '테스트 {name}',
    description: '테스트 설명',
    createdAt: DateTime(2024),
    isCompleted: false,
  );

  group('Get{Name}sUseCase', () {
    test('{name} 목록을 반환한다', () async {
      // Arrange
      when(() => mockRepository.get{Name}s())
          .thenAnswer((_) async => Success([sample{Name}]));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<Success<List<{Name}Entity>>>());
      final items = (result as Success<List<{Name}Entity>>).data;
      expect(items.length, 1);
      expect(items.first.id, '1');
      verify(() => mockRepository.get{Name}s()).called(1);
    });

    test('Repository 실패 시 Failure를 반환한다', () async {
      // Arrange
      when(() => mockRepository.get{Name}s())
          .thenAnswer((_) async => Failure(AppFailure.server('서버 에러')));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<Failure>());
    });
  });
}
```

---

## 생성 후 실행 명령

파일을 모두 생성한 다음 반드시 순서대로 실행합니다:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

- `build_runner`가 실패하면 오류 메시지를 확인해 `part` 지시어나 `@riverpod`/`@freezed` 어노테이션 오류를 수정합니다.
- `flutter analyze`가 경고를 내면 내용을 사용자에게 보고합니다.

---

## 체크리스트

생성 완료 후 사용자에게 다음을 안내합니다:

- [ ] 생성된 파일 목록과 경로 표시
- [ ] `{name}_providers.dart`의 `dioProvider` import 경로가 프로젝트와 일치하는지 확인 요청
- [ ] `{name}_list_screen.dart`를 `app_router.dart`에 라우트로 등록할 것 안내
- [ ] 추가 UseCase(create, update, delete)가 필요하면 같은 패턴으로 확장하면 됨을 안내
- [ ] build_runner / flutter analyze 결과 출력

---

## 주의사항

- `pubspec.yaml`의 `dependencies`를 절대 수정하지 않습니다. freezed/riverpod 패키지가 없으면 사용자에게 추가를 제안만 합니다.
- `print()` 대신 `AppLogger`를 사용합니다.
- `dynamic` 타입은 사용하지 않습니다.
- `presentation`에서 `data` 레이어를 직접 import하지 않습니다 (ViewModel은 providers를 통해 UseCase만 접근).
