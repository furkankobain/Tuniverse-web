import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Paginated list view widget
/// Firestore collection'ları için lazy loading
class PaginatedListView<T> extends StatefulWidget {
  final Query<Map<String, dynamic>> query;
  final T Function(DocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final Widget Function(BuildContext, T) listItemBuilder;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  
  const PaginatedListView({
    super.key,
    required this.query,
    required this.itemBuilder,
    required this.listItemBuilder,
    this.pageSize = 20,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query<Map<String, dynamic>> query = widget.query.limit(widget.pageSize);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newItems = snapshot.docs
          .map((doc) => widget.itemBuilder(doc))
          .toList();

      setState(() {
        _items.addAll(newItems);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ?? _buildError();
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          return widget.listItemBuilder(context, _items[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henüz içerik yok',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

/// Paginated grid view widget
class PaginatedGridView<T> extends StatefulWidget {
  final Query<Map<String, dynamic>> query;
  final T Function(DocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final Widget Function(BuildContext, T) gridItemBuilder;
  final int pageSize;
  final int crossAxisCount;
  final double childAspectRatio;
  
  const PaginatedGridView({
    super.key,
    required this.query,
    required this.itemBuilder,
    required this.gridItemBuilder,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> query = widget.query.limit(widget.pageSize);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newItems = snapshot.docs
          .map((doc) => widget.itemBuilder(doc))
          .toList();

      setState(() {
        _items.addAll(newItems);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.gridItemBuilder(context, _items[index]);
      },
    );
  }
}
