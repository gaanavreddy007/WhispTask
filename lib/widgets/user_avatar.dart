// ignore_for_file: deprecated_member_use, unused_import, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final bool showOnlineIndicator;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 30,
    this.showEditButton = false,
    this.onEditPressed,
    this.showOnlineIndicator = false,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Avatar
        _buildAvatar(context),
        
        // Edit Button
        if (showEditButton) _buildEditButton(context),
        
        // Online Indicator
        if (showOnlineIndicator) _buildOnlineIndicator(),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = radius;
    
    // If user has a photo URL, show network image
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: backgroundColor ?? theme.colorScheme.surface,
        backgroundImage: NetworkImage(user.photoUrl!),
        onBackgroundImageError: (error, stackTrace) {
          // Fallback to initials if image fails to load
          debugPrint('Failed to load user avatar: $error');
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      );
    }
    
    // Fallback to initials avatar
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: backgroundColor ?? _getInitialsBackgroundColor(user.displayName),
      child: Text(
        user.initials,
        style: textStyle ?? TextStyle(
          color: Colors.white,
          fontSize: _getFontSize(avatarRadius),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: onEditPressed ?? () => _showEditOptions(context),
        child: Container(
          width: radius * 0.6,
          height: radius * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            size: radius * 0.25,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: radius * 0.4,
        height: radius * 0.4,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }

  Color _getInitialsBackgroundColor(String name) {
    // Generate a color based on the first character of the name
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFF57C00), // Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFD32F2F), // Red
      const Color(0xFF0097A7), // Cyan
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
      const Color(0xFFE64A19), // Deep Orange
      const Color(0xFF303F9F), // Indigo
    ];
    
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  double _getFontSize(double radius) {
    if (radius <= 20) return 12;
    if (radius <= 30) return 16;
    if (radius <= 40) return 20;
    if (radius <= 50) return 24;
    return 28;
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              AppLocalizations.of(context).changeProfilePicture,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditOption(
                  context,
                  AppLocalizations.of(context).camera,
                  Icons.camera_alt,
                  Theme.of(context).colorScheme.primary,
                  () => _pickFromCamera(context),
                ),
                _buildEditOption(
                  context,
                  AppLocalizations.of(context).gallery,
                  Icons.photo_library,
                  Colors.green,
                  () => _pickFromGallery(context),
                ),
                _buildEditOption(
                  context,
                  AppLocalizations.of(context).remove,
                  Icons.delete,
                  Theme.of(context).colorScheme.error,
                  () => _removePhoto(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _pickFromCamera(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).photoTaken),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).failedToTakePhoto}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pickFromGallery(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).imageSelected),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).failedToPickImage}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).photoRemoved),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Custom Avatar Variations

class UserAvatarList extends StatelessWidget {
  final List<UserModel> users;
  final double radius;
  final int maxVisible;
  final VoidCallback? onMorePressed;

  const UserAvatarList({
    super.key,
    required this.users,
    this.radius = 20,
    this.maxVisible = 3,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxVisible).toList();
    final remainingCount = users.length - maxVisible;

    return Row(
      children: [
        ...visibleUsers.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          
          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : radius * -0.5),
            child: UserAvatar(
              user: user,
              radius: radius,
            ),
          );
        }),
        
        if (remainingCount > 0) ...[
          Container(
            margin: EdgeInsets.only(left: radius * -0.5),
            child: GestureDetector(
              onTap: onMorePressed,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: radius * 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class UserAvatarWithStatus extends StatelessWidget {
  final UserModel user;
  final double radius;
  final String status;
  final Color statusColor;

  const UserAvatarWithStatus({
    super.key,
    required this.user,
    required this.status,
    this.radius = 30,
    this.statusColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            UserAvatar(
              user: user,
              radius: radius,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.displayName.split(' ').first, // First name only
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class AnimatedUserAvatar extends StatefulWidget {
  final UserModel user;
  final double radius;
  final Duration animationDuration;
  final bool showEditButton;

  const AnimatedUserAvatar({
    super.key,
    required this.user,
    this.radius = 30,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showEditButton = false,
  });

  @override
  State<AnimatedUserAvatar> createState() => _AnimatedUserAvatarState();
}

class _AnimatedUserAvatarState extends State<AnimatedUserAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1, // Subtle rotation
            child: UserAvatar(
              user: widget.user,
              radius: widget.radius,
              showEditButton: widget.showEditButton,
            ),
          ),
        );
      },
    );
  }

  void replay() {
    _animationController.reset();
    _animationController.forward();
  }
}