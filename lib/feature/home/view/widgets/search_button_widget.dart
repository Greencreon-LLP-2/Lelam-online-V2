import 'package:flutter/material.dart';

class SearchState {
  static final SearchState _instance = SearchState._internal();
  factory SearchState() => _instance;
  SearchState._internal();

  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  final ValueNotifier<bool> isSearchFocused = ValueNotifier<bool>(false);

  void clearSearch() {
    searchQuery.value = '';
    isSearchFocused.value = false;
  }

  void resetOnNavigation() {
    clearSearch();
  }
}

class SearchButtonWidget extends StatefulWidget {
  final FocusNode focusNode;
  final Function(String) onSearch;

  const SearchButtonWidget({
    super.key,
    required this.focusNode,
    required this.onSearch,
  });

  @override
  State<SearchButtonWidget> createState() => _SearchButtonWidgetState();
}

class _SearchButtonWidgetState extends State<SearchButtonWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: SearchState().searchQuery.value);
    SearchState().searchQuery.addListener(_updateController);
  }

  @override
  void dispose() {
    SearchState().searchQuery.removeListener(_updateController);
    _controller.dispose();
    super.dispose();
  }

  void _updateController() {
    if (_controller.text != SearchState().searchQuery.value) {
      _controller.text = SearchState().searchQuery.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
     
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SearchState().searchQuery,
      builder: (context, query, _) {
        return TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: 'Search products...',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      SearchState().clearSearch();
                      widget.focusNode.unfocus();
                      
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = SearchState().searchQuery.value.trim();
                    widget.onSearch(query);
                  },
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            SearchState().searchQuery.value = value;
            
          },
          onSubmitted: (value) {
            widget.onSearch(value.trim());
          },
          onTap: () {
            SearchState().isSearchFocused.value = true;
          
          },
        );
      },
    );
  }
}