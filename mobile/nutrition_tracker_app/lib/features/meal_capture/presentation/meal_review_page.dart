import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/glass_surface.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../meal_history/data/meal_history_repository.dart';
import '../data/meal_repository.dart';
import '../domain/meal_review.dart';
import 'meal_photo.dart';

class MealReviewPage extends ConsumerStatefulWidget {
  const MealReviewPage({required this.mealId, super.key});
  final String mealId;
  @override
  ConsumerState<MealReviewPage> createState() => _MealReviewPageState();
}

class _FoodResolutionChoice {
  const _FoodResolutionChoice(
      {this.food,
      this.custom,
      this.review,
      this.resolved = false,
      required this.grams,
      required this.preparationMethod});
  final FoodSearchItem? food;
  final CustomFoodDraft? custom;
  final MealReview? review;
  final bool resolved;
  final double grams;
  final String preparationMethod;
}

class _FoodResolverSheet extends StatefulWidget {
  const _FoodResolverSheet(
      {required this.repository, required this.mealId, required this.item});
  final MealRepository repository;
  final String mealId;
  final MealReviewItem item;
  @override
  State<_FoodResolverSheet> createState() => _FoodResolverSheetState();
}

class _FoodResolverSheetState extends State<_FoodResolverSheet> {
  late final TextEditingController _query;
  late final TextEditingController _grams;
  late final TextEditingController _preparation;
  List<FoodSearchItem> _foods = [];
  bool _searching = false,
      _askingAi = false,
      _estimating = false,
      _canEstimate = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.item.detectedName);
    _grams = TextEditingController(
        text: (widget.item.grams ?? 100).toStringAsFixed(0));
    _preparation = TextEditingController(text: widget.item.preparationMethod);
  }

  @override
  void dispose() {
    _query.dispose();
    _grams.dispose();
    _preparation.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    final result = await widget.repository.searchFoods(_query.text.trim());
    if (!mounted) return;
    setState(() => _searching = false);
    if (result is Success<List<FoodSearchItem>>) {
      setState(() => _foods = result.value);
    } else if (result is Failure<List<FoodSearchItem>>) {
      setState(() => _error = result.failure.message);
    }
  }

  Future<void> _askAi() async {
    setState(() {
      _askingAi = true;
      _error = null;
    });
    final result = await widget.repository
        .resolveFood(widget.mealId, widget.item.id, query: _query.text.trim());
    if (!mounted) return;
    setState(() => _askingAi = false);
    if (result is Success<FoodResolutionResult>) {
      setState(() {
        _foods = result.value.suggestions;
        _canEstimate = result.value.suggestions.isEmpty;
      });
      if (result.value.suggestions.isEmpty) {
        setState(() => _error = result.value.noMatchReason ??
            'AI found no safe catalog match. You can request a reviewed nutrition estimate.');
      }
    } else if (result is Failure<FoodResolutionResult>) {
      setState(() => _error = result.failure.message);
    }
  }

  Future<void> _estimate() async {
    final grams = double.tryParse(_grams.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Enter a positive gram value first.');
      return;
    }
    setState(() {
      _estimating = true;
      _error = null;
    });
    final result = await widget.repository.resolveFood(
        widget.mealId, widget.item.id,
        query: _query.text.trim(), mode: 'NutritionEstimate');
    if (!mounted) return;
    setState(() => _estimating = false);
    if (result is Failure<FoodResolutionResult>) {
      setState(() => _error = result.failure.message);
      return;
    }
    final estimate = (result as Success<FoodResolutionResult>).value.estimate;
    if (estimate == null) {
      setState(
          () => _error = 'AI could not produce a safe nutrition estimate.');
      return;
    }
    final reviewed = await showDialog<CustomFoodDraft>(
        context: context,
        builder: (_) => _CustomFoodDialog(
            initialName: estimate.name,
            initialDraft: CustomFoodDraft(
                name: estimate.name,
                description: estimate.description ?? '',
                calories: estimate.calories,
                protein: estimate.protein,
                carbs: estimate.carbs,
                fat: estimate.fat,
                fibre: estimate.fibre),
            warning: '${estimate.warning}\n${estimate.assumptions.join(' ')}'));
    if (!mounted || reviewed == null) return;
    setState(() => _estimating = true);
    final confirmed = await widget.repository.confirmEstimatedFood(
        widget.mealId, widget.item.id,
        estimate: estimate,
        reviewed: reviewed,
        grams: grams,
        preparationMethod: _preparation.text.trim().isEmpty
            ? estimate.preparationMethod
            : _preparation.text.trim());
    if (!mounted) return;
    setState(() => _estimating = false);
    if (confirmed is Success<MealReview>) {
      Navigator.pop(
          context,
          _FoodResolutionChoice(
              resolved: true,
              review: confirmed.value,
              grams: grams,
              preparationMethod: estimate.preparationMethod));
    } else {
      setState(
          () => _error = (confirmed as Failure<MealReview>).failure.message);
    }
  }

  void _choose(FoodSearchItem food) {
    final grams = double.tryParse(_grams.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Enter a positive gram value first.');
      return;
    }
    Navigator.pop(
        context,
        _FoodResolutionChoice(
            food: food,
            grams: grams,
            preparationMethod: _preparation.text.trim().isEmpty
                ? food.preparationMethod
                : _preparation.text.trim()));
  }

  Future<void> _custom() async {
    final draft = await showDialog<CustomFoodDraft>(
        context: context,
        builder: (_) =>
            _CustomFoodDialog(initialName: widget.item.detectedName));
    if (!mounted || draft == null) return;
    final grams = double.tryParse(_grams.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Enter a positive gram value first.');
      return;
    }
    Navigator.pop(
        context,
        _FoodResolutionChoice(
            custom: draft,
            grams: grams,
            preparationMethod: _preparation.text.trim().isEmpty
                ? 'Unknown'
                : _preparation.text.trim()));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resolve ${widget.item.detectedName}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    const Text(
                        'Choose a catalog food. Nutrition comes from the selected record.'),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _query,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _search(),
                              decoration: const InputDecoration(
                                  labelText: 'Search food',
                                  prefixIcon: Icon(Icons.search)))),
                      const SizedBox(width: 8),
                      IconButton.filled(
                          onPressed: _searching ? null : _search,
                          icon: _searching
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.search))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _grams,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration:
                                  const InputDecoration(labelText: 'Grams'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: _preparation,
                              decoration: const InputDecoration(
                                  labelText: 'Preparation')))
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                            onPressed: _askingAi ? null : _askAi,
                            icon: _askingAi
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_askingAi
                                ? 'Asking AI…'
                                : 'Ask AI for catalog matches'))),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.warning))
                    ],
                    if (_canEstimate)
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: _estimating ? null : _estimate,
                              icon: _estimating
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.science_outlined),
                              label: Text(_estimating
                                  ? 'Estimating…'
                                  : 'Estimate nutrition with AI'))),
                    const SizedBox(height: 8),
                    Expanded(
                        child: _foods.isEmpty
                            ? const Center(
                                child: Text(
                                    'Search the catalog or ask AI for suggestions.'))
                            : ListView.builder(
                                itemCount: _foods.length,
                                itemBuilder: (context, index) {
                                  final food = _foods[index];
                                  return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(food.name),
                                      subtitle: Text(
                                          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100 g${food.isVerified ? ' • verified' : ''}${food.isEstimate ? ' • AI estimate' : ''}${food.confidence > 0 ? ' • AI-ranked catalog match' : ''}'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => _choose(food));
                                })),
                    SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                            onPressed: _custom,
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Add custom food manually')))
                  ]))));
}

class _CustomFoodDialog extends StatefulWidget {
  const _CustomFoodDialog(
      {required this.initialName, this.initialDraft, this.warning});
  final String initialName;
  final CustomFoodDraft? initialDraft;
  final String? warning;
  @override
  State<_CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<_CustomFoodDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _fibre;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _name = TextEditingController(text: draft?.name ?? widget.initialName);
    _description = TextEditingController(text: draft?.description ?? '');
    _calories =
        TextEditingController(text: draft?.calories.toStringAsFixed(1) ?? '');
    _protein =
        TextEditingController(text: draft?.protein.toStringAsFixed(1) ?? '');
    _carbs = TextEditingController(text: draft?.carbs.toStringAsFixed(1) ?? '');
    _fat = TextEditingController(text: draft?.fat.toStringAsFixed(1) ?? '');
    _fibre = TextEditingController(text: draft?.fibre.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _calories,
      _protein,
      _carbs,
      _fat,
      _fibre
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  void _save() {
    final values = [
      _number(_calories),
      _number(_protein),
      _number(_carbs),
      _number(_fat),
      _number(_fibre)
    ];
    if (_name.text.trim().isEmpty ||
        values.any((value) => value == null || value < 0) ||
        values.first == 0) {
      setState(() => _error =
          'Enter a name and non-negative nutrition values. Calories must be greater than zero.');
      return;
    }
    Navigator.pop(
        context,
        CustomFoodDraft(
            name: _name.text.trim(),
            description: _description.text.trim(),
            calories: values[0]!,
            protein: values[1]!,
            carbs: values[2]!,
            fat: values[3]!,
            fibre: values[4]!));
  }

  Widget _field(TextEditingController controller, String label) => TextField(
      controller: controller,
      keyboardType: label == 'Name' || label == 'Description'
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label));

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.initialDraft == null
              ? 'Add custom food'
              : 'Review AI estimate'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(_name, 'Name'),
            _field(_description, 'Description'),
            _field(_calories, 'Calories per 100 g'),
            _field(_protein, 'Protein per 100 g'),
            _field(_carbs, 'Carbs per 100 g'),
            _field(_fat, 'Fat per 100 g'),
            _field(_fibre, 'Fibre per 100 g'),
            if (widget.warning != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(widget.warning!,
                      style: const TextStyle(color: AppColors.warning))),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.warning)))
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(onPressed: _save, child: const Text('Save and apply'))
          ]);
}

class _MealReviewPageState extends ConsumerState<MealReviewPage> {
  late Future<Result<MealReview>> _future;
  int _reviewRevision = 0;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _reviewRevision++;
    _future = ref.read(mealRepositoryProvider).review(widget.mealId);
  }

  Future<void> _refresh() async {
    final revision = ++_reviewRevision;
    final future = ref.read(mealRepositoryProvider).review(widget.mealId);
    setState(() => _future = future);
    await future;
    if (!mounted || revision != _reviewRevision) return;
  }

  void _applyReview(MealReview review) {
    _reviewRevision++;
    setState(() => _future = Future.value(Success(review)));
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final result =
        await ref.read(mealRepositoryProvider).confirm(widget.mealId);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result is Success<MealReview>) {
      ref.invalidate(dashboardRepositoryProvider);
      ref.invalidate(mealHistoryRepositoryProvider);
      context.go(RoutePaths.home);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meal confirmed. Today has been refreshed.')));
    }
  }

  Future<void> _edit(MealReviewItem item) async {
    final grams =
        TextEditingController(text: (item.grams ?? 0).toStringAsFixed(0));
    final saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Edit ${item.detectedName}'),
                content: TextField(
                    controller: grams,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grams')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'))
                ]));
    if (saved == true) {
      final result = await ref.read(mealRepositoryProvider).updateItem(
          widget.mealId, item,
          grams: double.tryParse(grams.text) ?? 0,
          preparationMethod: item.preparationMethod,
          foodId: item.foodId);
      if (!mounted) return;
      if (result is Success<MealReview>) {
        _applyReview(result.value);
      } else if (result is Failure<MealReview>) {
        _showFailure(result.failure);
      }
    }
    grams.dispose();
  }

  Future<void> _resolveItem(MealReviewItem item) async {
    final choice = await showModalBottomSheet<_FoodResolutionChoice>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _FoodResolverSheet(
            repository: ref.read(mealRepositoryProvider),
            mealId: widget.mealId,
            item: item));
    if (!mounted || choice == null) return;

    if (choice.resolved) {
      if (choice.review != null) _applyReview(choice.review!);
      return;
    }

    var foodId = choice.food?.id;
    if (choice.custom != null) {
      final created = await ref
          .read(mealRepositoryProvider)
          .createCustomFood(choice.custom!);
      if (!mounted) return;
      if (created is! Success<String>) {
        _showFailure((created as Failure<String>).failure);
        return;
      }
      foodId = created.value;
    }
    if (foodId == null) return;
    final result = await ref.read(mealRepositoryProvider).updateItem(
        widget.mealId, item,
        grams: choice.grams,
        preparationMethod: choice.preparationMethod,
        foodId: foodId);
    if (!mounted) return;
    if (result is Success<MealReview>) {
      _applyReview(result.value);
    } else if (result is Failure<MealReview>) {
      _showFailure(result.failure);
    }
  }

  void _showFailure(AppFailure failure) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.message)));

  Future<void> _addFood() async {
    final query = TextEditingController();
    final grams = TextEditingController(text: '100');
    var foods = <FoodSearchItem>[];
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: query,
                      decoration:
                          const InputDecoration(labelText: 'Search food'),
                      onSubmitted: (_) async {
                        final result = await ref
                            .read(mealRepositoryProvider)
                            .searchFoods(query.text);
                        if (result is Success<List<FoodSearchItem>>) {
                          setSheetState(() => foods = result.value);
                        }
                      }),
                  const SizedBox(height: 10),
                  TextField(
                      controller: grams,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Grams')),
                  ...foods.map((food) => ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100 g'),
                      onTap: () async {
                        final result = await ref
                            .read(mealRepositoryProvider)
                            .addItem(widget.mealId,
                                foodId: food.id,
                                grams: double.tryParse(grams.text) ?? 0,
                                preparationMethod: 'Unknown');
                        if (context.mounted) Navigator.pop(context);
                        if (!mounted) return;
                        if (result is Success<MealReview>) {
                          _applyReview(result.value);
                        } else if (result is Failure<MealReview>) {
                          _showFailure(result.failure);
                        }
                      }))
                ]))));
    query.dispose();
    grams.dispose();
  }

  Future<void> _corrections() async {
    final result =
        await ref.read(mealRepositoryProvider).corrections(widget.mealId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: result is Success<List<MealCorrection>> &&
                    result.value.isNotEmpty
                ? ListView(shrinkWrap: true, children: [
                    Text('Correction history',
                        style: Theme.of(context).textTheme.titleLarge),
                    ...result.value.map((entry) => ListTile(
                        title: Text(entry.type),
                        subtitle: Text(
                            '${entry.predictedGrams?.toStringAsFixed(0) ?? '-'} g to ${entry.correctedGrams?.toStringAsFixed(0) ?? '-'} g')))
                  ])
                : const SizedBox(
                    height: 100,
                    child:
                        Center(child: Text('No corrections recorded yet.')))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('Food details'),
          centerTitle: true),
      body: FutureBuilder<Result<MealReview>>(
          future: _future,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (result is! Success<MealReview>) {
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Review unavailable — retry')));
            }
            final meal = result.value;
            return Stack(fit: StackFit.expand, children: [
              Positioned.fill(
                  bottom: MediaQuery.sizeOf(context).height * .34,
                  child: MealPhoto(
                      mealId: meal.mealId,
                      hasImage: meal.hasImage,
                      hero: true)),
              DraggableScrollableSheet(
                  initialChildSize: .64,
                  minChildSize: .48,
                  maxChildSize: .88,
                  snap: true,
                  builder: (context, controller) => GlassSurface(
                      padding: EdgeInsets.zero,
                      radius: 34,
                      blur: 30,
                      opacity: Theme.of(context).brightness == Brightness.dark
                          ? .9
                          : .8,
                      child: Column(children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              controller: controller,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 20),
                              children: [
                                Center(
                                    child: Container(
                                        width: 44,
                                        height: 5,
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                            borderRadius:
                                                BorderRadius.circular(9)))),
                                const SizedBox(height: 18),
                                Text(meal.name ?? 'Meal analysis',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const SizedBox(height: 14),
                                _energy(context, meal),
                                if (meal.hasIncompleteNutrition) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(.14),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Text(
                                          'Nutrition is incomplete. Resolve every highlighted food before confirming.')),
                                ],
                                const SizedBox(height: 12),
                                Wrap(spacing: 9, runSpacing: 9, children: [
                                  _macro(context, 'Carbs', meal.totalCarbs,
                                      AppColors.warning),
                                  _macro(context, 'Protein', meal.totalProtein,
                                      AppColors.green),
                                  _macro(context, 'Fat', meal.totalFat,
                                      AppColors.cyan),
                                  _macro(context, 'Fibre', meal.totalFibre,
                                      AppColors.violet)
                                ]),
                                const SizedBox(height: 14),
                                Text(
                                    meal.provider.toLowerCase() == 'mock'
                                        ? 'Simulated analysis — review every estimate.'
                                        : '${meal.provider}${meal.model == null ? '' : ' • ${meal.model}'} analysis',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.softInk,
                                        fontWeight: FontWeight.w600)),
                                if (meal.warnings.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(.14),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(meal.warnings.first)),
                                ],
                                const SizedBox(height: 22),
                                Text('Detected foods',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                ...meal.items.map((item) => _item(item)),
                                OutlinedButton.icon(
                                    onPressed: _addFood,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add food item')),
                                TextButton.icon(
                                    onPressed: _corrections,
                                    icon: const Icon(Icons.history),
                                    label: const Text('Correction history')),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: meal.status == 'Confirmed' ||
                                      _confirming ||
                                      meal.items.any((item) =>
                                          item.nutritionMatchState ==
                                          'Unresolved')
                                  ? null
                                  : _confirm,
                              icon: _confirming
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(_confirming
                                  ? 'Confirming meal'
                                  : meal.status == 'Confirmed'
                                      ? 'Meal confirmed'
                                      : meal.items.any((item) =>
                                              item.nutritionMatchState ==
                                              'Unresolved')
                                          ? 'Resolve ${meal.items.where((item) => item.nutritionMatchState == 'Unresolved').length} food item${meal.items.where((item) => item.nutritionMatchState == 'Unresolved').length == 1 ? '' : 's'} to confirm'
                                          : 'Confirm meal'),
                            ),
                          ),
                        ),
                      ])))
            ]);
          }));

  Widget _item(MealReviewItem item) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.detectedName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(_statusText(item),
            style: const TextStyle(fontSize: 12, color: AppColors.softInk)),
      ]),
      subtitle: Text(
          '${item.grams?.toStringAsFixed(0) ?? '?'} g  •  ${item.calories?.toStringAsFixed(0) ?? 'Nutrition unavailable'}${item.calories == null ? '' : ' kcal'}\n${item.nutritionMatchState == 'Unresolved' ? 'Resolve this food with search or AI assistance' : 'Recognition ${(item.recognitionConfidence * 100).toStringAsFixed(0)}%  •  nutrition ${(item.nutritionMatchConfidence * 100).toStringAsFixed(0)}%'}'),
      trailing: PopupMenuButton<String>(
          onSelected: (choice) async {
            if (choice == 'resolve') await _resolveItem(item);
            if (choice == 'edit') await _edit(item);
            if (choice == 'remove') {
              final result = await ref
                  .read(mealRepositoryProvider)
                  .removeItem(widget.mealId, item.id);
              if (!mounted) return;
              if (result is Success<MealReview>) _applyReview(result.value);
            }
          },
          itemBuilder: (_) => [
                if (item.nutritionMatchState == 'Unresolved')
                  const PopupMenuItem(
                      value: 'resolve', child: Text('Correct food'))
                else
                  const PopupMenuItem(value: 'edit', child: Text('Edit grams')),
                const PopupMenuItem(value: 'remove', child: Text('Remove'))
              ]));

  String _statusText(MealReviewItem item) => switch (item.nutritionMatchState) {
        'AiCatalogMatch' => 'AI catalog match — review before confirming',
        'AiEstimate' => 'AI estimate — review before confirming',
        'UserSelected' || 'UserDefined' => 'User corrected',
        'Unresolved' => 'Needs attention — correct this food manually',
        _ => 'Catalog match — review portion before confirming',
      };

  Widget _energy(BuildContext context, MealReview meal) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.62),
          borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        const Icon(Icons.local_fire_department, color: AppColors.danger),
        const SizedBox(width: 9),
        const Expanded(
            child: Text('Total energy', overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: AnimatedCount(meal.totalCalories,
                suffix: ' kcal', style: Theme.of(context).textTheme.titleLarge),
          ),
        )
      ]));

  Widget _macro(
          BuildContext context, String label, double value, Color color) =>
      Container(
          width: (MediaQuery.sizeOf(context).width - 70) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(.56),
              borderRadius: BorderRadius.circular(21)),
          child: Row(children: [
            Icon(Icons.circle, size: 11, color: color),
            const SizedBox(width: 7),
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(0)}g',
                style: const TextStyle(fontWeight: FontWeight.w800))
          ]));
}
