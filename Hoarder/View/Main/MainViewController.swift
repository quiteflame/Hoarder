//
//  MainViewController.swift
//  Hoarder
//
//  Created by Karol Moluszys on 02.05.2018.
//  Copyright © 2018 Karol Moluszys. All rights reserved.
//

import UIKit
import RealmSwift
import BarcodeScanner
import RxSwift
import RxCocoa

enum ScannerMode {
    case none
    case add
    case search
}

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var notificationToken: NotificationToken? = nil
    var scannerMode = ScannerMode.none
    let realmService = RealmService()
    let addCodeSubject = PublishSubject<String>()
    let searchCodeSubject = PublishSubject<String>()
    let bag = DisposeBag()
    let barcodeViewController = BarcodeScannerViewController()
    var content: Results<Movie>? {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        content = realmService.getAll()

        setupUI()
        bind()
        startRealmNotification()
    }

    deinit {
        notificationToken?.invalidate()
    }

    @IBAction func addAction(sender: UIBarButtonItem) {
        scannerMode = .add
        presentBarcodeScanner()
    }

    @IBAction func searchAction(sender: UIBarButtonItem) {
        scannerMode = .search
        presentBarcodeScanner()
    }

    @IBAction func addSearched(sender: UIButton) {
        guard let code = searchBar.text else {
            return
        }

        guard !code.isEmpty else {
            return
        }

        showAlert(withCode: code)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let vc = segue.destination as! DetailViewController
            vc.movie = sender as? Movie
            vc.service = realmService
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

private extension MainViewController {
    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        barcodeViewController.codeDelegate = self
        barcodeViewController.errorDelegate = self
        barcodeViewController.dismissalDelegate = self
        barcodeViewController.isOneTimeSearch = true
    }

    func bind() {
        addCodeSubject
            .delay(1.0, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] code in
                guard let this = self else { return }

                if !this.search(code: code) {
                    this.store(code: code)
                    this.barcodeViewController.reset()
                } else {
                    this.barcodeViewController.messageViewController.errorTintColor = .red
                    this.barcodeViewController.resetWithError(message: "You have that one!")
                }
            })
            .disposed(by: bag)

        searchCodeSubject
            .delay(1.0, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] code in
                guard let this = self else { return }
                let result = this.search(code: code)
                this.barcodeViewController.messageViewController.errorTintColor = result ? .red : .green
                this.barcodeViewController.resetWithError(message: result ? "You have that one!" : "Let's hoard it!")
            })
            .disposed(by: bag)

        searchBar.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let text = text else {
                    return
                }

                guard !text.isEmpty else {
                    self?.content = self?.realmService.getAll()
                    return
                }
                
                self?.content = self?.realmService.search(code: text)
            })
            .disposed(by: bag)
    }

    func startRealmNotification() {
        // Observe Results Notifications
        notificationToken = realmService.getAll().observe { [weak self] (changes: RealmCollectionChange) in
            guard let this = self else { return }

            this.title = "Hoarder (\(this.realmService.getAll().count))"

            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                this.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                this.tableView.beginUpdates()
                this.tableView.insertRows(at: insertions.map {
                    IndexPath(row: $0, section: 0)
                }, with: .automatic)
                this.tableView.deleteRows(at: deletions.map {
                    IndexPath(row: $0, section: 0)
                }, with: .automatic)
                this.tableView.reloadRows(at: modifications.map {
                    IndexPath(row: $0, section: 0)
                }, with: .automatic)
                this.tableView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }

    func presentBarcodeScanner() {
        present(barcodeViewController, animated: true, completion: nil)
    }

    func store(code: String) {
        realmService.store(code: code)
    }

    func store(titlePL: String) {
        realmService.store(titlePL: titlePL)
    }

    func store(titleORG: String) {
        realmService.store(titleORG: titleORG)
    }

    func search(code: String) -> Bool {
        return realmService.search(code: code)
    }

    func delete(movie: Movie) {
        realmService.delete(movie: movie)
    }

    func reset() {
        content = realmService.getAll()
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }

    func showAlert(withCode code: String) {
        let alert = UIAlertController(title: "Save as...", message: nil, preferredStyle: .actionSheet)
        let codeAction = UIAlertAction(title: "Code", style: .default) { [weak self] action in
            self?.reset()
            self?.store(code: code)
        }
        let titlePLAction = UIAlertAction(title: "Title PL", style: .default) { [weak self] action in
            self?.reset()
            self?.store(titlePL: code)
        }
        let titleORGAction = UIAlertAction(title: "Title ORG", style: .default) { [weak self] action in
            self?.reset()
            self?.store(titleORG: code)
        }
        alert.addAction(codeAction)
        alert.addAction(titlePLAction)
        alert.addAction(titleORGAction)

        present(alert, animated: true, completion: nil)
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let movie = content?[indexPath.row] else {
            return cell
        }

        cell.textLabel?.text = movie.code.isEmpty ? (movie.titlePL.isEmpty ? movie.titleORG : movie.titlePL) : movie.code

        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let movie = content?[indexPath.row] else {
            return
        }

        performSegue(withIdentifier: "showDetail", sender: movie)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let movie = content?[indexPath.row] else {
                return
            }

            delete(movie: movie)
        }
    }
}

extension MainViewController: BarcodeScannerCodeDelegate {
    func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
        print("poszlo")
        switch scannerMode {
        case .add:
            addCodeSubject.onNext(code)
        case .search:
            searchCodeSubject.onNext(code)
        default:
            break
        }
    }
}

extension MainViewController: BarcodeScannerErrorDelegate {
    func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
        print(error)
        controller.resetWithError(message: error.localizedDescription)
    }
}

extension MainViewController: BarcodeScannerDismissalDelegate {
    func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
