import 'package:flutter/material.dart';
import 'package:melaq/l10n/app_localizations.dart';
import '../../../../constants.dart';

class OnbordingContent extends StatelessWidget {
  const OnbordingContent({
    super.key,
    this.isTextOnTop = false,
    required this.title,
    required this.description,
    required this.image,
  });

  final bool isTextOnTop;
  final String title, description, image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),

        if (isTextOnTop)
          OnbordTitleDescription(
            title: title,
            description: description,
          ),
        if (isTextOnTop) const Spacer(),

        /// if you are using SVG then replace [Image.asset] with [SvgPicture.asset]

        Image.asset(
          image,
          height: 250,
        ),
        if (!isTextOnTop) const Spacer(),
        if (!isTextOnTop)
          OnbordTitleDescription(
            title: AppLocalizations.of(context)!.welcomeapp,
            description: AppLocalizations.of(context)!.welcomeapp_detils,
          ),

        const Spacer(),
      ],
    );
  }
}

class OnbordTitleDescription extends StatelessWidget {
  const OnbordTitleDescription({
    super.key,
    required this.title,
    required this.description,
  });

  final String title, description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: defaultPadding),
        Text(
          description,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
