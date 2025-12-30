import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/conversation/conversation_chat.dart';
import 'package:provider/provider.dart';
import '../../../provider/avatar_provider.dart';
import '../../../utils/app_style.dart';
import '../../../models/avatar_model.dart';
import 'widgets/avatar_selector.dart';

class SelectAvatar extends StatefulWidget {
  const SelectAvatar({super.key});

  @override
  State<SelectAvatar> createState() => _SelectAvatarState();
}

class _SelectAvatarState extends State<SelectAvatar> {
  AvatarModel _selectedAvatar = AvatarModel.clara;

  void _onAvatarSelected(AvatarModel avatar) {
    setState(() {
      _selectedAvatar = avatar;
    });
  }

  void _startConversation() {
    // 1. Save the selected avatar to the Provider
    Provider.of<AvatarProvider>(
      context,
      listen: false,
    ).selectAvatar(_selectedAvatar);
    // Pass the selected avatar to the next screen
    // Navigator.pushNamed(
    //   context,
    //   '/ConversationChat',
    // arguments: {
    //   'avatarId': _selectedAvatar.id,
    //   'avatarName': _selectedAvatar.name,
    //   'avatarModelPath': _selectedAvatar.modelPath,
    //   'avatarColor': _selectedAvatar.accentColor.value,
    // },
    // );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationChat(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primaryOrange,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Choose Your Companion",
          style: TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Subtitle
              Text(
                'Select your companion for the conversation',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Avatar Selector
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AvatarSelector(
                    selectedAvatar: _selectedAvatar,
                    onAvatarSelected: _onAvatarSelected,
                  ),
                  // For flutter_3d_controller, use:
                  // AvatarSelector3D(
                  //   selectedAvatar: _selectedAvatar,
                  //   onAvatarSelected: _onAvatarSelected,
                  // ),
                ),
              ),

              // Start Conversation Button
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                child: GestureDetector(
                  onTap: _startConversation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _selectedAvatar.accentColor,
                          _selectedAvatar.accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedAvatar.accentColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Start with ${_selectedAvatar.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
