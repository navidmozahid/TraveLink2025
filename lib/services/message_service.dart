import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// ✅ Send message in an existing conversation
  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // 1) Insert message
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'text': text,
    });

    // 2) Update last message in conversation
    await supabase.from('conversations').update({
      'last_message': text,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// ✅ Soft delete message (only sender)
  Future<void> deleteMessage(String messageId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('messages').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
      'text': null,
    }).eq('id', messageId).eq('sender_id', userId);
  }

  /// ✅ Delete chat for me only (hides from inbox)
  Future<void> deleteChatForMe(String conversationId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('conversation_deletes').insert({
      'conversation_id': conversationId,
      'user_id': userId,
    });
  }

  /// ✅ ✅ NEW: Restore chat for me (show again in inbox)
  Future<void> restoreChatForMe(String conversationId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('conversation_deletes')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  /// ✅ Get existing conversation or create new one
  Future<String> getOrCreateConversation(String otherUserId) async {
    final myId = supabase.auth.currentUser!.id;

    // ✅ Check if conversation exists between both users
    final existing = await supabase
        .from('conversations')
        .select()
        .or(
      'and(user1_id.eq.$myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$myId)',
    )
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    // ✅ Create new conversation
    final created = await supabase
        .from('conversations')
        .insert({
      'user1_id': myId,
      'user2_id': otherUserId,
      'last_message': '',
      'last_message_at': DateTime.now().toIso8601String(),
    })
        .select()
        .single();

    return created['id'];
  }

  /// ✅ Mark all received messages as read (Instagram style)
  Future<void> markConversationAsRead(String conversationId) async {
    final myId = supabase.auth.currentUser!.id;

    await supabase.from('messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('conversation_id', conversationId).neq('sender_id', myId).eq(
      'is_read',
      false,
    );
  }

  /// ✅ Count unread messages for inbox badge
  Future<int> countUnreadMessages(String conversationId) async {
    final myId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', myId)
        .eq('is_read', false);

    return data.length;
  }

  /// ✅ Set typing status (Instagram style) ✅ FIXED
  Future<void> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    final myId = supabase.auth.currentUser!.id;

    await supabase.from('typing_status').upsert(
      {
        'conversation_id': conversationId,
        'user_id': myId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'conversation_id,user_id',
    );
  }

  /// ✅ Send image/video message (Instagram style)
  Future<void> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required String mediaType, // "image" or "video"
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // 1) Insert media message
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'text': null,
      'media_url': mediaUrl,
      'media_type': mediaType,
    });

    // 2) Update conversation last message preview
    await supabase.from('conversations').update({
      'last_message': mediaType == "image" ? "📷 Photo" : "🎥 Video",
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// ✅ ✅ NEW: Send shared post message (Instagram share style)
  Future<void> sendSharedPostMessage({
    required String conversationId,
    required String sharedPostId,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // 1) Insert shared post message
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'text': null,
      'shared_post_id': sharedPostId,
    });

    // 2) Update conversation last message preview
    await supabase.from('conversations').update({
      'last_message': "📩 Shared a post",
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// ✅ NEW: Unsend message (Delete for everyone)
  Future<void> unsendMessage(String messageId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('messages').update({
      'deleted_for_everyone': true,
      'deleted_for_everyone_at': DateTime.now().toIso8601String(),
      'text': null,
      'media_url': null,
      'media_type': null,
    }).eq('id', messageId).eq('sender_id', userId);
  }
}
