import 'package:flutter/material.dart';

class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// true = navigates to named route
  /// false = shows a Switch
  final bool isLinkTile;

  final String? routeName;
  final bool initialSwitchValue;
  final ValueChanged<bool>? onSwitchChanged;

  SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isLinkTile = true,
    this.routeName,
    this.initialSwitchValue = false,
    this.onSwitchChanged,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.initialSwitchValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade400,
            width: 0.7,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(widget.icon, color: Colors.black87),
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 15),
        ),
        subtitle: widget.subtitle == null
            ? null
            : Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
        trailing: widget.isLinkTile
            ? Icon(Icons.chevron_right)
            : Switch(
                value: _switchValue,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _switchValue = val;
                  });
                  if (widget.onSwitchChanged != null) {
                    widget.onSwitchChanged!(val);
                  }
                },
              ),
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        onTap: widget.isLinkTile && widget.routeName != null
            ? () {
                Navigator.pushNamed(context, widget.routeName!);
              }
            : null,
      ),
    );
  }
}

